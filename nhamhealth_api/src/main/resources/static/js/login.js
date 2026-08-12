(() => {
    const url = new URL(window.location.href);
    if (url.searchParams.has('logout')) {
        document.querySelector('.notice-success')?.remove();
        if (window.Swal) {
            window.Swal.fire({
                title: 'Signed out',
                text: 'You have been signed out securely.',
                icon: 'success',
                confirmButtonColor: '#0b6b57'
            });
        } else {
            window.alert('You have been signed out securely.');
        }
        url.searchParams.delete('logout');
        window.history.replaceState({}, document.title, `${url.pathname}${url.search}${url.hash}`);
    }

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
