export async function notifyUser(title: string, body: string) {
  if (!('Notification' in window)) {
    return;
  }

  if (Notification.permission === 'default') {
    await Notification.requestPermission();
  }

  if (Notification.permission === 'granted') {
    new Notification(title, { body });
  }
}

