const status = document.querySelector('.copy-status');
for (const button of document.querySelectorAll('[data-copy]')) {
  button.hidden = false;
  button.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(button.dataset.copy);
      status.textContent = `Copied: ${button.dataset.copy}`;
    } catch {
      status.textContent = 'Could not copy automatically. Select the path above and copy it manually.';
    }
  });
}
