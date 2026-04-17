import './bootstrap';

const audioUploadForms = document.querySelectorAll('[data-upload-form]');

for (const form of audioUploadForms) {
    const trigger = form.querySelector('[data-audio-upload-trigger]');
    const input = form.querySelector('[data-audio-input]');

    if (!trigger || !input) {
        continue;
    }

    trigger.addEventListener('click', () => input.click());
    input.addEventListener('change', () => {
        if (!input.files || input.files.length === 0) {
            return;
        }

        const titleInput = form.querySelector('input[name="title"]');
        if (titleInput && input.files[0]) {
            titleInput.value = input.files[0].name.replace(/\.[^.]+$/, '');
        }

        form.submit();
    });
}

const recordTrigger = document.querySelector('[data-record-trigger]');
const recordForm = document.querySelector('[data-record-form]');
const recordInput = recordForm?.querySelector('[data-record-input]');

if (recordTrigger instanceof HTMLButtonElement && recordForm instanceof HTMLFormElement && recordInput instanceof HTMLInputElement) {
    let recorder;
    let chunks = [];

    const setLabel = (label) => {
        recordTrigger.textContent = label;
    };

    recordTrigger.addEventListener('click', async () => {
        if (recorder && recorder.state === 'recording') {
            recorder.stop();
            return;
        }

        if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === 'undefined') {
            window.alert('Captacao por microfone nao suportada neste navegador.');
            return;
        }

        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            chunks = [];
            recorder = new MediaRecorder(stream);

            recorder.addEventListener('dataavailable', (event) => {
                if (event.data.size > 0) {
                    chunks.push(event.data);
                }
            });

            recorder.addEventListener('stop', () => {
                const blob = new Blob(chunks, { type: recorder.mimeType || 'audio/webm' });
                const fileName = `captacao-web-${Date.now()}.webm`;
                const file = new File([blob], fileName, { type: blob.type });
                const transfer = new DataTransfer();
                transfer.items.add(file);
                recordInput.files = transfer.files;
                stream.getTracks().forEach((track) => track.stop());
                setLabel(recordTrigger.dataset.recordLabelStart || 'Iniciar captacao');
                recordForm.submit();
            });

            recorder.start();
            setLabel(recordTrigger.dataset.recordLabelStop || 'Parar captacao');
        } catch (error) {
            window.alert('Nao foi possivel iniciar a captacao por microfone.');
        }
    });
}
