/* Minimal enhancements — the site works fully without JavaScript. */

// Reveal-on-scroll (skipped if the user prefers reduced motion)
const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const targets = document.querySelectorAll('.reveal');
if (reduced || !('IntersectionObserver' in window)) {
  targets.forEach(el => el.classList.add('in'));
} else {
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
    });
  }, { threshold: 0.08 });
  targets.forEach(el => io.observe(el));
}

// Footer year
const y = document.getElementById('year');
if (y) y.textContent = new Date().getFullYear();
