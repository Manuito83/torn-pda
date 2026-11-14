typedef WatchNotice = ({String text, int seconds});

const String _screenOn = '\n\nYour phone screen will remain on, consider plugging it in.';

WatchNotice watcherNotice(bool on) =>
    on ? (text: 'Chain watcher activated!$_screenOn', seconds: 7) : (text: 'Chain watcher deactivated!', seconds: 5);

WatchNotice panicNotice(bool on, {required bool withWatcher}) => switch ((on, withWatcher)) {
  (false, _) => (text: 'Panic mode deactivated!', seconds: 5),
  (true, true) => (text: 'Chain watcher and panic mode have been activated!$_screenOn', seconds: 7),
  (true, false) => (text: 'Panic mode activated!', seconds: 7),
};
