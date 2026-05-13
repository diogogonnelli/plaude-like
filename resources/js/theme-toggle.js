function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    try { localStorage.setItem('spot-theme', theme); } catch (e) {}
    document.querySelectorAll('[data-theme-toggle]').forEach(function (btn) {
        btn.setAttribute('aria-pressed', String(theme === 'light'));
        const labelEl = btn.querySelector('[data-theme-toggle-label]');
        const icon = theme === 'dark' ? '☾' : '☀';
        if (labelEl) {
            labelEl.textContent = icon;
        } else if (!btn.dataset.themeTogglePreserve) {
            btn.textContent = icon;
        }
    });
}

function currentTheme() {
    return document.documentElement.getAttribute('data-theme') || 'dark';
}

document.addEventListener('click', function (event) {
    var trigger = event.target.closest('[data-theme-toggle]');
    if (!trigger) return;
    event.preventDefault();
    applyTheme(currentTheme() === 'dark' ? 'light' : 'dark');
});

document.addEventListener('DOMContentLoaded', function () {
    applyTheme(currentTheme());
});
