// Emil Vu (Hoang Tuan Kiet Vu)
//
// STM32F4 Traffic Light System with FreeRTOS
// This program implements a traffic light control system using FreeRTOS on an STM32F4 microcontroller.
// The system simulates traffic flow, controls traffic lights, generates cars, and displays the system state.

/* Standard includes */
#include <stdint.h>      // For standard integer types (uint16_t, etc.)
#include <stdio.h>       // For standard I/O functions
#include "stm32f4_discovery.h" // Board-specific definitions for STM32F4 Discovery board
#include "stm32f4xx_adc.h"      // ADC peripheral driver for STM32F4
#include "stm32f4xx_gpio.h"     // GPIO peripheral driver for STM32F4

/* FreeRTOS includes */
#include "stm32f4xx.h"   // STM32F4 specific definitions
#include "../FreeRTOS_Source/include/FreeRTOS.h"     // Core FreeRTOS functionality
#include "../FreeRTOS_Source/include/queue.h"       // FreeRTOS queue API for inter-task communication
#include "../FreeRTOS_Source/include/semphr.h"    // FreeRTOS semaphore API for synchronization
#include "../FreeRTOS_Source/include/task.h"     // FreeRTOS task management API
#include "../FreeRTOS_Source/include/timers.h"      // FreeRTOS software timer API

/* Traffic Light Definitions */
#define FLOW_MIN 0     // Minimum value for traffic flow sensor (ADC reading)
#define FLOW_MAX 4095   // Maximum value for traffic flow sensor (ADC reading) Maximum for 12 bit is 4095
#define TICK_RATE pdMS_TO_TICKS(100) // Convert 100ms to FreeRTOS ticks for task delays

// GPIO pin definitions for the traffic light LEDs and control signals

#define RED GPIO_Pin_0       // Pin for red traffic light
#define YELLOW GPIO_Pin_1    // Pin for yellow traffic light
#define GREEN GPIO_Pin_2     // Pin for green traffic light
#define POT GPIO_Pin_3       // Pin for potentiometer (analog input for flow simulation)
#define DATA GPIO_Pin_6      // Pin for shift register data line (for car display)
#define CLOCK GPIO_Pin_7     // Pin for shift register clock line
#define RESET GPIO_Pin_8     // Pin for shift register reset line
#define CAR_PRESENT 1        // Value indicating a car is present
#define CAR_ABSENT 0         // Value indicating no car is present

/* Function Declarations */
void TrafficFlowTask(void *pvParameters);      // Task to read and process traffic flow sensor
void TrafficLightTask(void *pvParameters);     // Task to control traffic light sequence
void TrafficGeneratorTask(void *pvParameters); // Task to generate new cars based on traffic flow
void SystemDisplayTask(void *pvParameters);    // Task to update visual display of the system
void TimerCallbackGreen(TimerHandle_t xTimer); // Timer callback for green light duration
void TimerCallbackYellow(TimerHandle_t xTimer); // Timer callback for yellow light duration
void TimerCallbackRed(TimerHandle_t xTimer);    // Timer callback for red light duration
void myGPIOC_Init(void);     // Initialize GPIO Port C pins
void myADC_Init(void);       // Initialize ADC for potentiometer reading
uint16_t ReadADC(void);      // Function to read the current ADC value

/* Global Queues */
xQueueHandle xQueueFlow = NULL;        // Queue to communicate traffic flow rate between tasks
xQueueHandle xQueueLight = NULL;       // Queue to communicate current traffic light state
xQueueHandle xQueueGenerator = NULL;   // Queue to communicate new car generation events

/* Timers */
TimerHandle_t xTimerGreen = NULL;      // Timer for green light duration
TimerHandle_t xTimerYellow = NULL;     // Timer for yellow light duration
TimerHandle_t xTimerRed = NULL;        // Timer for red light duration

int main(void)
{
    // Initialize GPIO and ADC hardware
    myGPIOC_Init();

    myADC_Init();

    // Create the communication queues with a size of 1 (only the latest value is needed)
    xQueueFlow = xQueueCreate(1, sizeof(int));         // Queue for flow rate
    xQueueLight = xQueueCreate(1, sizeof(uint16_t));   // Queue for light state
    xQueueGenerator = xQueueCreate(1, sizeof(int));    // Queue for car generation

    // Only proceed if all queues were created successfully
    if (xQueueFlow && xQueueLight && xQueueGenerator)
    {
        // Create the FreeRTOS tasks
        xTaskCreate(TrafficFlowTask, "FlowControl", configMINIMAL_STACK_SIZE,
NULL, 1, NULL);
        xTaskCreate(TrafficLightTask, "LightControl",
configMINIMAL_STACK_SIZE, NULL, 1, NULL);
        xTaskCreate(TrafficGeneratorTask, "TrafficGen",
configMINIMAL_STACK_SIZE, NULL, 1, NULL);
        xTaskCreate(SystemDisplayTask, "DisplaySystem",
configMINIMAL_STACK_SIZE, NULL, 1, NULL);

        // Create software timers for traffic light state durations
        // pdFALSE means timers are one-shot (not auto-reload)
        xTimerGreen = xTimerCreate("GreenTimer", pdMS_TO_TICKS(6000), pdFALSE,
0, TimerCallbackGreen); // Go to yellow
        xTimerYellow = xTimerCreate("YellowTimer", pdMS_TO_TICKS(3000),
pdFALSE, 0, TimerCallbackYellow); // go to red
        xTimerRed = xTimerCreate("RedTimer", pdMS_TO_TICKS(6000), pdFALSE, 0,
TimerCallbackRed); // go to green

        // Start the FreeRTOS scheduler - this function should never return
        vTaskStartScheduler();
    }

    // Should never reach here unless there was an error in initialization
    for (;;);
}

void myGPIOC_Init(void)
{
    // Enable clock for GPIO Port C
    RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOC, ENABLE);
    GPIO_InitTypeDef GPIO_InitStruct;

    // Configure pins for traffic lights and shift register as outputs
    GPIO_InitStruct.GPIO_Pin = RED | YELLOW | GREEN | DATA | CLOCK | RESET;

    GPIO_InitStruct.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitStruct.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOC, &GPIO_InitStruct);

    // Configure potentiometer pin as analog input
    GPIO_InitStruct.GPIO_Pin = POT;
    GPIO_InitStruct.GPIO_Mode = GPIO_Mode_AN; // Analog mode
    GPIO_InitStruct.GPIO_PuPd = GPIO_PuPd_NOPULL; // No pull-up/pull-down
    GPIO_Init(GPIOC, &GPIO_InitStruct);
}

void myADC_Init(void)
{
    // Enable clock for ADC1 peripheral
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC1, ENABLE);
    ADC_InitTypeDef ADC_InitStruct;

    // Configure ADC1 settings
    ADC_InitStruct.ADC_ContinuousConvMode = DISABLE; // Single conversion mode
    ADC_InitStruct.ADC_DataAlign = ADC_DataAlign_Right; // Right-aligned data
    ADC_InitStruct.ADC_Resolution = ADC_Resolution_12b; // 12-bit resolution (0-4095)
    ADC_InitStruct.ADC_ScanConvMode = DISABLE; // Scan only one channel
    ADC_InitStruct.ADC_ExternalTrigConv = DISABLE; // No external trigger
    ADC_InitStruct.ADC_ExternalTrigConvEdge = DISABLE; // No trigger edge

    ADC_Init(ADC1, &ADC_InitStruct);

    // Enable the ADC
    ADC_Cmd(ADC1, ENABLE);

    // Configure ADC channel 13 (connected to PC3/POT) with 144 cycle sample time
    ADC_RegularChannelConfig(ADC1, ADC_Channel_13, 1,
ADC_SampleTime_144Cycles);
}

uint16_t ReadADC(void)
{
    // Start ADC conversion
    ADC_SoftwareStartConv(ADC1);

    // Wait until conversion is complete (End Of Conversion flag)
    while (!ADC_GetFlagStatus(ADC1, ADC_FLAG_EOC));

    // Return the converted value (0-4095)
    return ADC_GetConversionValue(ADC1);

}

void TrafficFlowTask(void *pvParameters)
{
    int flowRate;
    for (;;)
    {
        // Read ADC value and convert to percentage (0-100%) based on defined min/max range
        flowRate = (100*((int)ReadADC() - FLOW_MIN) / (FLOW_MAX - FLOW_MIN));

        // Update the flow rate queue with the latest value (overwrite previous value)
        if(xQueueOverwrite(xQueueFlow, &flowRate))
        {
            vTaskDelay(TICK_RATE);
        }
    }
}

void TrafficLightTask(void *pvParameters)
{
    // Start the system with green light by starting the green timer
    xTimerStart(xTimerGreen, 0);

    // Update light queue with current state (GREEN)
    uint16_t light = GREEN;
    xQueueOverwrite(xQueueLight, &light);

    // This task initializes the light system then mostly waits
    // The timer callbacks handle the actual light changes
    for (;;)
    {
        vTaskDelay(100*TICK_RATE); // Long delay since work is done by timers
    }
}

void TimerCallbackGreen(TimerHandle_t xTimer)
{// at the end of green -> go to yellow state
    // Green light phase is over, start yellow light timer
    xTimerStart(xTimerYellow, 0);

    // Update current light state to YELLOW
    uint16_t light = YELLOW;
    xQueueOverwrite(xQueueLight, &light);
}

void TimerCallbackYellow(TimerHandle_t xTimer)

{// At the end of yellow -> go to red state
    int flow;

    // Read current traffic flow rate
    if (xQueuePeek(xQueueFlow, &flow, TICK_RATE) == pdPASS)
    {
        // Set red light duration based on flow rate (higher flow = shorter red light)
        xTimerChangePeriod(xTimerRed, pdMS_TO_TICKS(10000 - 50*flow), 0);

        // Update current light state to RED
        uint16_t light = RED;
        xQueueOverwrite(xQueueLight, &light);
    }
}

void TimerCallbackRed(TimerHandle_t xTimer)
{// at the end of red -> go to green state
    int flow;

    // Read current traffic flow rate
    if (xQueuePeek(xQueueFlow, &flow, TICK_RATE) == pdPASS)
    {
        // Set green light duration based on flow rate (higher flow = longer green light)
        xTimerChangePeriod(xTimerGreen, pdMS_TO_TICKS(5000 + 50*flow), 0);

        // Update current light state to GREEN
        uint16_t light = GREEN;
        xQueueOverwrite(xQueueLight, &light);
    }
}

void TrafficGeneratorTask(void *pvParameters)
{
    int car = CAR_PRESENT; // Always generate a car by default
    int flow;

    for (;;)
    {
        // Read current traffic flow rate
        if (xQueuePeek(xQueueFlow, &flow, TICK_RATE) == pdPASS)
        {
            // Generate a new car
            xQueueOverwrite(xQueueGenerator, &car);

           // Delay between car generation depends on flow rate
           // Higher flow = shorter delay (more frequent cars)

              // Delay range: 1200ms (flow=80%) to 4000ms (flow=0%)
              vTaskDelay(pdMS_TO_TICKS(4000 - 35*flow));
          }
      }
}

void SystemDisplayTask(void *pvParameters)
{
    uint16_t currentLight;
    int newCar;

      // Array to store car positions (20 positions total)
      // Positions 0-8: Cars before the stop line
      // Position 9: Stop line
      // Positions 10-19: Cars after the stop line
      int cars[20] = {CAR_ABSENT}; // Initialize all positions with CAR_ABSENT (0)

      // Initialize the shift register by pulsing RESET
      GPIO_SetBits(GPIOC, RESET);

      for(;;)
      {
          // 1. Update Traffic Light LEDs
          // Get current traffic light state from queue
          if (xQueuePeek(xQueueLight, &currentLight, TICK_RATE) == pdTRUE)
          {
              // Turn off all traffic lights first
              GPIO_ResetBits(GPIOC, RED);
              GPIO_ResetBits(GPIOC, YELLOW);
              GPIO_ResetBits(GPIOC, GREEN);

              // Turn on only the current active light
              GPIO_SetBits(GPIOC, currentLight);
          }

          // 2. Update Shift Register Display with car positions **MAIN ONE**
          for (int i = 20; i > 0; i--)
          {
              // Set DATA pin based on car presence at this position
              if (cars[i] == CAR_PRESENT)
                  GPIO_SetBits(GPIOC, DATA);
              else
                  GPIO_ResetBits(GPIOC, DATA);

              // Pulse CLOCK to shift in the data bit
              GPIO_SetBits(GPIOC, CLOCK);
              GPIO_ResetBits(GPIOC, CLOCK);

          }

          // 3. Update Car Positions based on Traffic Light State
          if (currentLight == GREEN)
          {
              // On GREEN: All cars move forward one position
              for (int i = 19; i > 0; i--)
                  cars[i] = cars[i-1];
/*
 * 000100
 * 100010
 * 010001
 * etc etc we just update array here
 */
        }
        else // YELLOW or RED
        {
            // On YELLOW/RED: Cars before stop line don't cross it
            // Only move a car forward if the space ahead is empty
            for (int i = 8; i > 0; i--)
            {
                if (cars[i] == CAR_ABSENT)
                {
                    cars[i] = cars[i-1];
                    cars[i-1] = CAR_ABSENT;
                }
            }

              // Cars after stop line continue moving regardless of light
              for (int i = 19; i > 9; i--)
              {
                  cars[i] = cars[i-1];
                  cars[i-1] = CAR_ABSENT;
              }

          }

          // 4. Check for New Cars
          // Try to receive a new car event from the generator queue
          cars[0] = CAR_ABSENT; //
          if (xQueueReceive(xQueueGenerator, &newCar, pdMS_TO_TICKS(100)) ==
pdTRUE)
          {
            // Add a new car at the beginning of the queue if signaled -> set the array of car
            if (newCar == CAR_PRESENT)
                cars[0] = CAR_PRESENT;
        }

        // Wait before next display update
        vTaskDelay(5*TICK_RATE);
    }
}

// The following functions are standard FreeRTOS hook functions
// that are called when specific system events occur void vApplicationMallocFailedHook(void)
{
    // Infinite loop to indicate error - system halts
    for(;;);
}

 void vApplicationStackOverflowHook(xTaskHandle pxTask, signed char
*pcTaskName)
 {
     (void) pcTaskName;
     (void) pxTask;

    // Infinite loop to indicate error - system halts
    for(;;);
}

void vApplicationIdleHook(void)
{
    volatile size_t xFreeStackSpace;
    xFreeStackSpace = xPortGetFreeHeapSize();

    if(xFreeStackSpace > 100)
    {

    }
}
