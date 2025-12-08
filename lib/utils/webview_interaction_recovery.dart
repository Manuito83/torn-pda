/// JavaScript payloads injected into the in-app browser to recover lost tap
/// interactions on iOS. When a Flutter dialog sits on top of `WKWebView`, iOS
/// can swallow the next touch event. The snippet re-dispatches that
/// gesture to the interactive element once the overlay disappears, and the
/// Dart side controls when it runs (via Remote Config)
class WebviewInteractionRecoveryScripts {
  const WebviewInteractionRecoveryScripts._();

  static const String installClickRestoreShim = r'''
(() => {
  try {
    const marker = '__tornPdaClickRestore';
    if (window[marker]) {
      return;
    }
    window[marker] = true;

    //console.log('[WebviewFull][ClickRestore] status=installed');

    const interactiveSelector = [
      'button',
      'a[href]',
      'input',
      'select',
      'textarea',
      '[role="button"]',
      '[role="tab"]',
      '[data-action]',
      '[data-interactive]',
      '[onclick]'
    ].join(',');

    const isDisabled = (element) => {
      return element.hasAttribute('disabled') || element.getAttribute('aria-disabled') === 'true';
    };

    const findInteractive = (start) => {
      if (!start) {
        return null;
      }
      if (start.closest) {
        return start.closest(interactiveSelector);
      }
      while (start) {
        if (start.matches && start.matches(interactiveSelector)) {
          return start;
        }
        start = start.parentElement;
      }
      return null;
    };

    const pointerToken = (eventLike) => {
      if (!eventLike) {
        return null;
      }
      if (typeof eventLike.pointerId === 'number') {
        return `p-${eventLike.pointerId}`;
      }
      if (eventLike.identifier !== undefined) {
        return `t-${eventLike.identifier}`;
      }
      return null;
    };

    const dispatchSyntheticClick = (target) => {
      if (!target) {
        return;
      }
      try {
        if (typeof target.click === 'function') {
          target.click();
          return;
        }
      } catch (directError) {
        console.debug('[WebviewFull][ClickRestore] click-failed', directError);
      }

      try {
        target.dispatchEvent(
          new MouseEvent('click', {
            bubbles: true,
            cancelable: true,
            view: window,
            detail: 1,
          }),
        );
      } catch (dispatchError) {
        console.debug('[WebviewFull][ClickRestore] dispatch-failed', dispatchError);
      }
    };

    const recentDispatch = {
      element: null,
      time: 0
    };

    const shouldSkipRepeat = (element, now) => {
      if (recentDispatch.element === element && now - recentDispatch.time < 250) {
        return true;
      }
      recentDispatch.element = element;
      recentDispatch.time = now;
      return false;
    };

    const activePointers = new Set();

    const registerPointerStart = (event) => {
      try {
        if (!event) {
          return;
        }

        if (event.changedTouches && event.changedTouches.length) {
          for (let i = 0; i < event.changedTouches.length; i++) {
            const token = pointerToken(event.changedTouches[i]);
            if (token) {
              activePointers.add(token);
            }
          }
        }

        const eventToken = pointerToken(event);
        if (eventToken) {
          activePointers.add(eventToken);
        }
      } catch (registerError) {
        console.debug('[WebviewFull][ClickRestore] register-error', registerError);
      }
    };

    const pointerHandler = (event) => {
      try {
        if (!event) {
          return;
        }

        let pointerKey = null;
        if (event.changedTouches && event.changedTouches.length) {
          pointerKey = pointerToken(event.changedTouches[0]);
        }
        if (!pointerKey) {
          pointerKey = pointerToken(event);
        }

        if (event.defaultPrevented) {
          if (pointerKey) {
            activePointers.delete(pointerKey);
          }
          return;
        }

        if (pointerKey && !activePointers.has(pointerKey)) {
          return;
        }

        const touch = event.changedTouches && event.changedTouches[0];
        const clientX = touch ? touch.clientX : event.clientX;
        const clientY = touch ? touch.clientY : event.clientY;
        const origin = document.elementFromPoint(clientX, clientY) || event.target;
        const interactive = findInteractive(origin);
        if (!interactive || isDisabled(interactive)) {
          if (pointerKey) {
            activePointers.delete(pointerKey);
          }
          return;
        }

        let nativeClick = false;
        const nativeListener = () => {
          nativeClick = true;
        };
        interactive.addEventListener('click', nativeListener, true);

        setTimeout(() => {
          interactive.removeEventListener('click', nativeListener, true);
          if (pointerKey) {
            activePointers.delete(pointerKey);
          }
          if (nativeClick) {
            return;
          }

          const now = Date.now();
          if (shouldSkipRepeat(interactive, now)) {
            return;
          }

          dispatchSyntheticClick(interactive);
        }, 24);
      } catch (handlerError) {
        console.debug('[WebviewFull][ClickRestore] handler-error', handlerError);
      }
    };

    document.addEventListener('touchstart', registerPointerStart, true);
    document.addEventListener('pointerdown', registerPointerStart, true);
    document.addEventListener('touchend', pointerHandler, true);
    document.addEventListener('pointerup', pointerHandler, true);
  } catch (error) {
    console.debug('[WebviewFull][ClickRestore] install-failed', error);
  }
})();
''';
}
