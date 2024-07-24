
async function checkAuth() {
    const response = await fetch('/auth');
    const result = await response.json();
    if (result.status !== 'ok')
        window.location = '/login.html';
}

checkAuth();
setTimeout(checkAuth, 30000);