(() => {
    const password = document.querySelector('#password');
    const toggle = document.querySelector('[data-password-toggle]');
    const toggleLabel = document.querySelector('[data-toggle-label]');

    if (password && toggle && toggleLabel) {
        toggle.addEventListener('click', () => {
            const isVisible = password.type === 'text';
            password.type = isVisible ? 'password' : 'text';
            toggleLabel.textContent = isVisible ? 'Show' : 'Hide';
            toggle.setAttribute('aria-label', isVisible ? 'Show password' : 'Hide password');
            password.focus();
        });
    }

    const form = document.querySelector('.login-form');
    const submitButton = document.querySelector('[data-submit-button]');
    const submitLabel = document.querySelector('[data-submit-label]');

    if (form && submitButton && submitLabel) {
        form.addEventListener('submit', () => {
            submitButton.disabled = true;
            submitButton.setAttribute('aria-busy', 'true');
            submitLabel.textContent = 'Signing in…';
        });
    }
})();
