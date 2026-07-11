// Emil Vu (Hoang Tuan Kiet Vu)
#include <stdint.h>
#include <stdio.h>
#include "stm32f4_discovery.h"
// FreeRTOS includes
#include "stm32f4xx.h"
#include "../FreeRTOS_Source/include/FreeRTOS.h"
#include "../FreeRTOS_Source/include/queue.h"
#include "../FreeRTOS_Source/include/semphr.h"
#include "../FreeRTOS_Source/include/task.h"
#include "../FreeRTOS_Source/include/timers.h"
//--------------------------------------------------------------
// Configuration Macros
//--------------------------------------------------------------
#define INCLUDE_vTaskSuspend          1 // logic macro definition
#define INCLUDE_vTaskDelete           1
#define configUSE_TIMERS              1
#define configSUPPORT_DYNAMIC_ALLOCATION 1
#define QUEUE_LEN                     10
#define PAUSE_PRIO                    0     // Lowest priority for paused tasks
#define RUN_PRIO                      1     // Running task's priority
#define AUX_PRIO                      2     // Auxiliary tasks (monitor, generator)
#define DDS_PRIO                      3     // Highest priority for DDS task
#define MONITOR_INTERVAL              100   // Monitor period in ms
// For Test bench 1
#define TASK_GEN_INTERVAL             250   // Task generator period in ms
// Task periods and execution times (in milliseconds)
#define TASK1_EXEC                    95
#define TASK1_PERIOD                  500
#define TASK2_EXEC                    150
#define TASK2_PERIOD                  500
#define TASK3_EXEC                    250
#define TASK3_PERIOD                  750
//// For Test bench 2
//#define TASK_GEN_INTERVAL             250   // Task generator period in ms
//
//// Task periods and execution times (in milliseconds)
//#define TASK1_EXEC                    95
//#define TASK1_PERIOD                  200
//
//#define TASK2_EXEC                    150
//#define TASK2_PERIOD                  500
//
//#define TASK3_EXEC                    250
//#define TASK3_PERIOD                  750
//// For Test bench 3
//#define TASK_GEN_INTERVAL             500   // Task generator period in ms
//
//// Task periods and execution times (in milliseconds)
//#define TASK1_EXEC                    100
//#define TASK1_PERIOD                  500
//
//#define TASK2_EXEC                    200
//#define TASK2_PERIOD                  500
//
//#define TASK3_EXEC                    200
//#define TASK3_PERIOD                  500
//--------------------------------------------------------------
// Data Structures
//--------------------------------------------------------------
typedef enum {
    PERIODIC,
    APERIODIC
} taskType;
typedef struct ddTask {
    TaskHandle_t      taskHandle;       // FreeRTOS task handle
    TaskFunction_t    taskFunc;         // Pointer to task function
    taskType          type;             // PERIODIC or APERIODIC
    char             *taskID;           // Task identifier (e.g., "T1")
    uint32_t          taskNum;          // Numeric identifier
    uint32_t          releaseTime;      // Release time (ms)
    uint32_t          absDeadline;      // Absolute deadline (ms)
    uint32_t          completionTime;   // Completion time (ms)
} ddTask_t;
typedef struct ddTaskNode {
    ddTask_t             task;          // DD-Task data
    struct ddTaskNode   *next;          // Pointer to next node in the list
} ddTaskNode_t;
typedef enum {
    RELEASE_EVENT,  // Request to release a task
    COMPLETE_EVENT, // Request to complete a task
    OVERDUE_EVENT,  // Request to mark a task overdue
    GET_LISTS,      // Request to get all task lists
    GET_ACTIVE,     // Request to get active list
    GET_COMPLETE,   // Request to get complete list
    GET_OVERDUE     // Request to get overdue list
} EventType;
typedef struct {
    EventType reqType;  // Type of request
    ddTask_t  task;  // Relevant task data (if applicable)
} DDSMessage_t;
//--------------------------------------------------------------
// Global Variables (Queues, Semaphores, Timers)
//--------------------------------------------------------------
xQueueHandle requestQueue = 0;        // Queue for sending DDS messages
xQueueHandle outputQueue = 0;         // Queue for returning task lists
SemaphoreHandle_t semRelease = 0;     // Semaphore to trigger task release
SemaphoreHandle_t semUpdate  = 0;     // Semaphore to trigger monitor update
TimerHandle_t sysTimer       = 0;     // Timer for system timekeeping
TimerHandle_t deadlineTimer  = 0;     // Timer for checking deadlines
TimerHandle_t genTimer       = 0;     // Timer for triggering task generation
TimerHandle_t monitorTimer   = 0;     // Timer for triggering monitor task
//--------------------------------------------------------------
// Function Prototypes
//--------------------------------------------------------------
static void setupHardware(void);
void delayMS(uint32_t ms);
uint32_t getCurrentTime(void);
// DDS Interface Functions
BaseType_t releaseTask(ddTask_t task);
BaseType_t completeTask(void);
void getTaskLists(ddTaskNode_t **active, ddTaskNode_t **overdue, ddTaskNode_t **complete);
void getActiveList(ddTaskNode_t **active);
void getCompleteList(ddTaskNode_t **complete);
void getOverdueList(ddTaskNode_t **overdue);
// Task List Management
BaseType_t insertTask(ddTaskNode_t **activeList, ddTask_t newTask);
BaseType_t removeTask(ddTaskNode_t **activeList, ddTaskNode_t **retiredList);
BaseType_t pauseScheduler(ddTaskNode_t **activeList);
BaseType_t updateScheduler(ddTaskNode_t **activeList);
// FreeRTOS Tasks
void deadlineSchedulerTask(void *pvParameters);
void taskGeneratorTask(void *pvParameters);
void monitorTask(void *pvParameters);
// User Task Functions
void userTask1(void *pvParameters);
void userTask2(void *pvParameters);
void userTask3(void *pvParameters);
// Timer Callback Functions
void deadlineTimerCallback(TimerHandle_t xTimer);
void systemTimerCallback(TimerHandle_t xTimer);
void referenceTimerCallback(TimerHandle_t xTimer);
//--------------------------------------------------------------
// Main Function Overall execution
/*
 taskGeneratorTask() builds a ddTask_t with userTask1 as its function.
It sends that to DDS via releaseTask().
deadlineSchedulerTask() receives it.
Calls insertTask() -> creates the task with priority 0.
Then updateScheduler() -> raises priority to 1. and RUN the code
After that go to userTask1 and actually start the task
based on the active, complete, overdue, the program check for the next course of action, informing DDS accordingly
Every 250ms, the generator checks for task releases.
DDS keeps scheduling tasks in earliest-deadline-first order.
User tasks keep simulating work and either complete or overrun.
Monitor keeps reporting system status every 100ms.
DDS keeps all task states updated dynamically.
 */
//--------------------------------------------------------------
int main(void) {
    setupHardware();
    // Create queues for DDS messages and outputs - Initializes interrupt controller
    requestQueue = xQueueCreate(QUEUE_LEN, sizeof(DDSMessage_t)); // main DDS event queue (task release, completion, overdue).
    outputQueue  = xQueueCreate(QUEUE_LEN, sizeof(ddTaskNode_t **)); // used to send active/complete/overdue lists back to monitor.
    // Create core DDS tasks
    xTaskCreate(deadlineSchedulerTask, "DDS", 5000, NULL, DDS_PRIO, NULL); // create central scheduler logic (highest priority).
    xTaskCreate(monitorTask, "MONITOR", configMINIMAL_STACK_SIZE, NULL, AUX_PRIO, NULL); // create prints task stats.
    xTaskCreate(taskGeneratorTask, "GEN", configMINIMAL_STACK_SIZE, NULL, AUX_PRIO, NULL); // generates periodic tasks.
    // Create semaphores for synchronization - used to trigger task actions from timer callbacks
    semRelease = xSemaphoreCreateBinary(); // For taskGenerator
    semUpdate  = xSemaphoreCreateBinary(); // for monitorTask
    // Create and start system timers
    sysTimer = xTimerCreate("SysTimer", 1 / portTICK_PERIOD_MS, pdTRUE, (void *)0, systemTimerCallback);
    //1ms periodic timer. Increments internal time counter (TimerID).
    xTimerStart(sysTimer, 0);
    //  dynamically adjusted for the current task's deadline.
    deadlineTimer = xTimerCreate("DeadlineTimer", 10000 / portTICK_PERIOD_MS, pdFALSE, (void *)1, deadlineTimerCallback);
    xTimerStop(deadlineTimer, 0);
    // Fires periodically to trigger task generation.
    genTimer = xTimerCreate("GenTimer", pdMS_TO_TICKS(TASK_GEN_INTERVAL), pdTRUE, (void *)2, referenceTimerCallback);
    xTimerStart(genTimer, 0);
    // Triggers monitor task to print status.
    monitorTimer = xTimerCreate("MonitorTimer", pdMS_TO_TICKS(MONITOR_INTERVAL), pdTRUE, (void *)3, referenceTimerCallback);
    xTimerStart(monitorTimer, 0);
    vTaskStartScheduler();  // Start FreeRTOS
    /*
     The three created tasks are now running:
    deadlineSchedulerTask() (priority 3 - highest)
    monitorTask() (priority 2)
    taskGeneratorTask() (priority 2)
    Since DDS_PRIO = 3, the scheduler immediately runs:
     */
    while (1); // Infinite loop (never reached unless scheduler fails).
    return 0;
}
//--------------------------------------------------------------
/* RUN FIRST Deadline Scheduler Task Central DDS logic (receives task release/completion events, manages task lists).
Listens on requestQueue for events (release, complete, overdue).
Handles:
RELEASE_EVENT -> insert new task in the active list (sorted by deadline).
COMPLETE_EVENT -> move head task to complete list.
OVERDUE_EVENT -> move head task to overdue list if past deadline.
Maintains 3 task lists: activeList, completeList, overdueList
Pauses the currently running task before any change using pauseScheduler.
Updates the scheduler (updateScheduler) to set the priority and deadline timer.
*/
//--------------------------------------------------------------
void deadlineSchedulerTask(void *pvParameters) {
    BaseType_t status; // to check if the queue give any message
    ddTaskNode_t *activeList = NULL; // linkedlist for currently running or ready to run task
    ddTaskNode_t *overdueList = NULL; // linkedlist for tasks that missed the deadnline
    ddTaskNode_t *completeList = NULL; // Tasks hat finished
    uint32_t currentTime = 0;
    for (;;) {
        DDSMessage_t msg;
        status = xQueueReceive(requestQueue, &msg, portMAX_DELAY); // wait for the message, store value in msg than wait
        // here until requestQueue receive a message -> go to taskGeneratorTask() and trigger DDS to release event -> releaseTask
        currentTime = getCurrentTime();
        // after release event 1 got trigger, check the status and proceed
        if (status) {
            EventType event = msg.reqType; //  tells us what kind of message it is.
            ddTask_t receivedTask = msg.task; // has all the task details
            if (event >= GET_LISTS) {
                // Handle status requests
                switch (event) {
                    case GET_LISTS:
                        xQueueSend(outputQueue, &activeList, 0);
                        xQueueSend(outputQueue, &completeList, 0);
                        xQueueSend(outputQueue, &overdueList, 0);
                        break;
                    case GET_ACTIVE:
                        xQueueSend(outputQueue, &activeList, 0);
                        break;
                    case GET_COMPLETE:
                        xQueueSend(outputQueue, &completeList, 0);
                        break;
                    case GET_OVERDUE:
                        xQueueSend(outputQueue, &overdueList, 0);
                        break;
                    default:
                        break;
                }
            } else {
                // Before processing an event, pause the current active task
                /*
                 If we already had a running task, we lower its priority.
                So it won't interrupt us while we decide who should run next.
                 */
                pauseScheduler(&activeList);
                switch (event) {
                    case RELEASE_EVENT: // go first
                        insertTask(&activeList, receivedTask); // Insert new task into active list
                        break;
                    case COMPLETE_EVENT: // go second, after task finished
                        removeTask(&activeList, &completeList); // after that remove the finished task from the active list
                        break;
                    case OVERDUE_EVENT:
                        if (activeList && (activeList->task.absDeadline < getCurrentTime()))
                            removeTask(&activeList, &overdueList);
                        break;
                    default:
                        break;
                }
                updateScheduler(&activeList); // go to updateScheduler
            }
        }
        // Memory management: if heap is low, free nodes from completeList
        if (xPortGetFreeHeapSize() < 5000) {
            printf("Memory Full\n");
            ddTaskNode_t *node;
            while (completeList != NULL) {
                node = completeList;
                completeList = completeList->next;
                vPortFree(node);
            }
        }
    }
}
//--------------------------------------------------------------
// Task List Management Functions
//--------------------------------------------------------------
//Inserts new task into activeList, maintaining deadline order.
BaseType_t insertTask(ddTaskNode_t **activeList, ddTask_t newTask) { // create new node and put the task inside -> to next task
    if (*activeList == NULL) {
        *activeList = (ddTaskNode_t *)pvPortMalloc(sizeof(ddTaskNode_t));
        (*activeList)->task = newTask;
        (*activeList)->next = NULL;
        //Create the task (userTask1()) -> Run the task
        xTaskCreate(newTask.taskFunc, newTask.taskID, configMINIMAL_STACK_SIZE, NULL, 0, &((*activeList)->task.taskHandle));
    } else {
        ddTaskNode_t *current = *activeList;
        ddTaskNode_t *previous = NULL;
        while (current != NULL && newTask.absDeadline >= current->task.absDeadline) {
            previous = current;
            current = current->next;
        }
        ddTaskNode_t *newNode = (ddTaskNode_t *)pvPortMalloc(sizeof(ddTaskNode_t));
        newNode->task = newTask;
        newNode->next = current;
        xTaskCreate(newTask.taskFunc, newTask.taskID, configMINIMAL_STACK_SIZE, NULL, 0, &newNode->task.taskHandle);
        if (previous != NULL)
            previous->next = newNode;
        else
            *activeList = newNode;
    }
    return pdTRUE;
}
//Removes the head of activeList (usually after completion or overdue) and adds it to either complete or overdue list.
BaseType_t removeTask(ddTaskNode_t **activeList, ddTaskNode_t **retiredList) {
    if (*activeList == NULL)
        return pdFALSE;
    ddTaskNode_t *node = *activeList;
    *activeList = (*activeList)->next; // // Move the list pointer forward -> to next task
    node->task.completionTime = getCurrentTime(); // // Save completion time
    printf("Task ID: %s, Release: %d, Complete: %d\n",
           node->task.taskID, node->task.releaseTime, node->task.completionTime); // and print to debug for the finshed task
    if (node->task.taskHandle != NULL)
        vTaskDelete(node->task.taskHandle); // after that, delete the task from memory. It's gone.
    node->next = *retiredList; // We move this task into the completeList for record-keeping.
    *retiredList = node;
    return pdTRUE;
}
//Sets active task priority to the lowest (PAUSE_PRIO).
BaseType_t pauseScheduler(ddTaskNode_t **activeList) {
    if (*activeList != NULL) {
        vTaskPrioritySet((*activeList)->task.taskHandle, PAUSE_PRIO);
        return pdTRUE;
    }
    return pdFALSE;
}
//Sets the top-priority task in activeList to RUN_PRIO and resets deadline timer.
BaseType_t updateScheduler(ddTaskNode_t **activeList) {
    if (*activeList != NULL) {
        //This sets the top task's priority to RUN_PRIO = 1. -> THIS is the line that actually triggers the task to run.
        // the task was created before, but setting the priority here to higher make it actually STARTS.
        vTaskPrioritySet((*activeList)->task.taskHandle, RUN_PRIO);
        uint32_t now = getCurrentTime();
        if ((*activeList)->task.absDeadline <= now) {
            xTimerChangePeriod(deadlineTimer, 1, 0);
        } else {
            xTimerChangePeriod(deadlineTimer, pdMS_TO_TICKS((*activeList)->task.absDeadline - now), 0);
        }
        xTimerReset(deadlineTimer, 0);
        // Starts or adjusts the deadlineTimer to expire when the task's deadline is reached.
        // Which task is running, when to check for overdue, and time to run the task
        return pdTRUE;
    } else {
        xTimerStop(deadlineTimer, 0);
        return pdFALSE;
    }
}
//--------------------------------------------------------------
// RUN SECOND: Task Generator Task Releases periodic tasks at fixed intervals.
/*
This runs every TASK_GEN_INTERVAL ms and does:
Tracks how much time has passed (t1, t2, t3) for each task.
If t1 is divisible by TASK1_PERIOD, it's time to generate T1.
It builds a ddTask_t with:
taskFunc: pointer to userTask1
absDeadline: now + period
Other metadata
Sends this to DDS using releaseTask().
*/
//--------------------------------------------------------------
void taskGeneratorTask(void *pvParameters) {
    uint32_t t1 = 0, t2 = 0, t3 = 0;
    uint32_t delta = TASK_GEN_INTERVAL;
    uint32_t now = 0;
    xSemaphoreGive(semRelease); // Initial trigger
    for (;;) {
        if (xSemaphoreTake(semRelease, portMAX_DELAY) == pdTRUE) {
            now = getCurrentTime();
            if ((t1 % TASK1_PERIOD) == 0) {
                uint32_t deadline = t1 + TASK1_PERIOD;
                ddTask_t task1 = {NULL, userTask1, PERIODIC, "T1", 1, now, deadline, 0};
                releaseTask(task1); // -> Run first after releaseTask got triggered
            }
            if ((t2 % TASK2_PERIOD) == 0) {
                uint32_t deadline = t2 + TASK2_PERIOD;
                ddTask_t task2 = {NULL, userTask2, PERIODIC, "T2", 2, now, deadline, 0};
                releaseTask(task2);
            }
            if ((t3 % TASK3_PERIOD) == 0) {
                uint32_t deadline = t3 + TASK3_PERIOD;
                ddTask_t task3 = {NULL, userTask3, PERIODIC, "T3", 3, now, deadline, 0};
                releaseTask(task3);
            }
            t1 += delta;
            t2 += delta;
            t3 += delta;
        }
    }
    vTaskDelete(NULL);
}
//--------------------------------------------------------------
// Monitor Task Periodically reports counts of active, completed, and overdue tasks.
/*
Triggered by semUpdate (via monitorTimer).
Gets all task lists using getActiveList, getCompleteList, and getOverdueList.
Prints current time and count of tasks in each category.
*/
//--------------------------------------------------------------
void monitorTask(void *pvParameters) {
    ddTaskNode_t *lists[3] = {NULL, NULL, NULL};  // [0]: Active, [1]: Complete, [2]: Overdue
    int counts[3] = {0, 0, 0};
    for (;;) {
        if (xSemaphoreTake(semUpdate, portMAX_DELAY) == pdTRUE) {
            getActiveList(&lists[0]);
            getCompleteList(&lists[1]);
            getOverdueList(&lists[2]);
            for (int i = 0; i < 3; i++) {
                counts[i] = 0;
                ddTaskNode_t *temp = lists[i];
                while (temp != NULL) {
                    counts[i]++;
                    temp = temp->next;
                }
            }
            printf("Time = %d | Active = %d | Complete = %d | Overdue = %d\n\n",
                   getCurrentTime(), counts[0], counts[1], counts[2]);
        }
    }
}
//--------------------------------------------------------------
// DDS Interface Functions
//--------------------------------------------------------------
BaseType_t releaseTask(ddTask_t task) {
    DDSMessage_t msg = {RELEASE_EVENT, task};
    return xQueueSend(requestQueue, &msg, portMAX_DELAY);
}
BaseType_t completeTask(void) {
    DDSMessage_t msg = {COMPLETE_EVENT, {0}}; // Sends a COMPLETE_EVENT message to DDS.
    return xQueueSend(requestQueue, &msg, portMAX_DELAY); // DDS will wake up from its xQueueReceive() call.
    // -> back to deadlineSchedulerTask
}
void getTaskLists(ddTaskNode_t **active, ddTaskNode_t **overdue, ddTaskNode_t **complete) {
    if (uxQueueSpacesAvailable(outputQueue) < QUEUE_LEN)
        xQueueReset(outputQueue);
    DDSMessage_t req = {GET_LISTS, {0}};
    xQueueSend(requestQueue, &req, portMAX_DELAY);
    xQueueReceive(outputQueue, active, portMAX_DELAY);
    xQueueReceive(outputQueue, overdue, portMAX_DELAY);
    xQueueReceive(outputQueue, complete, portMAX_DELAY);
}
void getActiveList(ddTaskNode_t **active) {
    if (uxQueueSpacesAvailable(outputQueue) < QUEUE_LEN)
        xQueueReset(outputQueue);
    DDSMessage_t req = {GET_ACTIVE, {0}};
    xQueueSend(requestQueue, &req, portMAX_DELAY);
    xQueueReceive(outputQueue, active, portMAX_DELAY);
}
void getCompleteList(ddTaskNode_t **complete) {
    if (uxQueueSpacesAvailable(outputQueue) < QUEUE_LEN)
        xQueueReset(outputQueue);
    DDSMessage_t req = {GET_COMPLETE, {0}};
    xQueueSend(requestQueue, &req, portMAX_DELAY);
    xQueueReceive(outputQueue, complete, portMAX_DELAY);
}
void getOverdueList(ddTaskNode_t **overdue) {
    if (uxQueueSpacesAvailable(outputQueue) < QUEUE_LEN)
        xQueueReset(outputQueue);
    DDSMessage_t req = {GET_OVERDUE, {0}};
    xQueueSend(requestQueue, &req, portMAX_DELAY);
    xQueueReceive(outputQueue, overdue, portMAX_DELAY);
}
//--------------------------------------------------------------
// User Task Functions Simulate user-defined periodic tasks with specific execution times.
//--------------------------------------------------------------
void userTask1(void *pvParameters) {
    delayMS(TASK1_EXEC); // simulate doing the task by giving it delay
    completeTask();// alarm DDS that the task is finished
    for (;;) ; // wait for response in the infinite loop
}
void userTask2(void *pvParameters) {
    delayMS(TASK2_EXEC);
    completeTask();
    for (;;) ;
}
void userTask3(void *pvParameters) {
    delayMS(TASK3_EXEC);
    completeTask();
    for (;;) ;
}
//--------------------------------------------------------------
// Timer Callback Functions
//--------------------------------------------------------------
//Sends OVERDUE_EVENT to DDS.
void deadlineTimerCallback(TimerHandle_t xTimer) {
    DDSMessage_t msg = {OVERDUE_EVENT, {0}};
    BaseType_t highPrio = pdFALSE;
    xQueueSendToFrontFromISR(requestQueue, &msg, &highPrio);
    if (highPrio)
        taskYIELD();
}
//Increments global system time by updating the TimerID
void systemTimerCallback(TimerHandle_t xTimer) {
    uint32_t curTime = (uint32_t)pvTimerGetTimerID(xTimer);
    curTime++;
    vTimerSetTimerID(xTimer, (void *)curTime);
}
//Triggers either task generation or monitoring depending on the timer ID.
void referenceTimerCallback(TimerHandle_t xTimer) {
    BaseType_t highPrio = pdFALSE;
    uint32_t timerID = (uint32_t)pvTimerGetTimerID(xTimer);
    if (timerID == 2) {
        xSemaphoreGiveFromISR(semRelease, &highPrio);
    } else {
        xSemaphoreGiveFromISR(semUpdate, &highPrio);
    }
    if (highPrio)
        taskYIELD();
}
//--------------------------------------------------------------
// Hardware and Utility Functions
//--------------------------------------------------------------
uint32_t getCurrentTime(void) {
    return (uint32_t)pvTimerGetTimerID(sysTimer);
}
void delayMS(uint32_t ms) {
    uint32_t start;
    for (; ms > 0; ms--) {
        start = xTaskGetTickCount();
        while ((xTaskGetTickCount() - start) == 0)
            ;
    }
}
static void setupHardware(void) {
    NVIC_SetPriorityGrouping(0);
}
//--------------------------------------------------------------
// FreeRTOS Hook Functions
//--------------------------------------------------------------
void vApplicationMallocFailedHook(void) {
    printf("SYSTEM OUT OF MEMORY");
    for (;;) ;
}
void vApplicationStackOverflowHook(xTaskHandle pxTask, signed char *pcTaskName) {
    (void)pxTask;
    (void)pcTaskName;
    for (;;) ;
}
void vApplicationIdleHook(void) {
    volatile size_t freeHeap = xPortGetFreeHeapSize();
    if (freeHeap > 100) {
        // Optionally adjust configuration if needed.
    }
}
