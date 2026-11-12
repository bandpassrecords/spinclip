// The homepage's few moving parts: the hero video's sound, the "How it
// works" steps, the looks gallery tabs, the screenshot lightbox, and the
// download card for the visitor's system.

// ── Hero sound ──
const video = document.getElementById('hero-video');
const sound = document.getElementById('sound-toggle');
const soundLabel = document.getElementById('sound-label');
if (video && sound && soundLabel) {
    const show = () => {
        const on = !video.muted && !video.paused;
        sound.setAttribute('aria-pressed', String(on));
        sound.classList.toggle('paused', video.muted);
        soundLabel.textContent = on ? 'Mute' : 'Play with sound';
    };
    sound.addEventListener('click', () => {
        if (video.muted) {
            // From the start, so the sound comes in with the intro.
            video.currentTime = 0;
            video.muted = false;
            video.play().catch(() => {});
        } else {
            video.muted = true;
        }
        show();
    });
    video.addEventListener('volumechange', show);
    show();
}

// ── How it works ──
const stepButtons = document.querySelectorAll('.step');
const stepShots = document.querySelectorAll('.how-shot img');
const selectStep = (i) => {
    stepButtons.forEach((b) => b.setAttribute('aria-selected', String(b.dataset.step === String(i))));
    stepShots.forEach((img) => img.classList.toggle('active', img.dataset.step === String(i)));
};
stepButtons.forEach((b) => b.addEventListener('click', () => selectStep(b.dataset.step)));

// ── Looks tabs ──
const tabs = document.querySelectorAll('.tab');
tabs.forEach((tab) =>
    tab.addEventListener('click', () => {
        tabs.forEach((t) => {
            const selected = t === tab;
            t.setAttribute('aria-selected', String(selected));
            document.getElementById(t.getAttribute('aria-controls')).hidden = !selected;
        });
    }),
);

// ── Lightbox ──
const lightbox = document.getElementById('lightbox');
const lightboxImg = document.getElementById('lightbox-img');
if (lightbox && lightboxImg) {
    const close = () => lightbox.classList.remove('open');
    document.querySelectorAll('img[data-zoom], .how-shot img').forEach((img) =>
        img.addEventListener('click', () => {
            lightboxImg.src = img.currentSrc || img.src;
            lightboxImg.alt = img.alt;
            lightbox.classList.add('open');
        }),
    );
    lightbox.addEventListener('click', close);
    document.addEventListener('keydown', (e) => e.key === 'Escape' && close());
}

// ── The download card for this computer ──
const ua = navigator.userAgent;
const os = /Mac/.test(ua) && !/iPhone|iPad/.test(ua) ? 'macos'
    : /Win/.test(ua) ? 'windows'
    : /Linux|X11/.test(ua) && !/Android/.test(ua) ? 'linux'
    : null;
if (os) document.querySelector(`.download-card[data-os="${os}"]`)?.classList.add('is-yours');
