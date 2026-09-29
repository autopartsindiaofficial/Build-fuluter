/**
 * Chat Sound Effects Utility
 * Uses Web Audio API to synthesize low-latency, native sound effects:
 * - Record Start Tone (WhatsApp-style soft high ping)
 * - Record Stop Tone (Soft release tick/pop)
 * - Trash / Discard Sound (Gentle swoosh)
 * - Send Sound (Subtle send confirmation pop)
 */

class ChatSoundEffects {
  private audioCtx: AudioContext | null = null;

  private getAudioContext(): AudioContext | null {
    if (typeof window === 'undefined') return null;
    try {
      if (!this.audioCtx) {
        const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
        if (AudioContextClass) {
          this.audioCtx = new AudioContextClass();
        }
      }
      if (this.audioCtx && this.audioCtx.state === 'suspended') {
        this.audioCtx.resume().catch(() => {});
      }
      return this.audioCtx;
    } catch (e) {
      return null;
    }
  }

  /**
   * Play WhatsApp-style Voice Note Start Beep
   * Crisp, soft rising ping (650Hz -> 880Hz)
   */
  playRecordStart(): void {
    try {
      const ctx = this.getAudioContext();
      if (!ctx) return;

      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      const now = ctx.currentTime;

      // Pitch sweep up for an encouraging "ready" chime
      osc.frequency.setValueAtTime(650, now);
      osc.frequency.exponentialRampToValueAtTime(880, now + 0.08);

      // Smooth envelope to avoid clicking
      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(0.18, now + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.13);
    } catch (e) {
      console.warn('[ChatSoundEffects] playRecordStart error:', e);
    }
  }

  /**
   * Play Record Stop / Release Click
   * Soft descending tick/snap (520Hz -> 320Hz)
   */
  playRecordStop(): void {
    try {
      const ctx = this.getAudioContext();
      if (!ctx) return;

      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      const now = ctx.currentTime;

      osc.frequency.setValueAtTime(520, now);
      osc.frequency.exponentialRampToValueAtTime(320, now + 0.06);

      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(0.14, now + 0.01);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.08);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.09);
    } catch (e) {
      console.warn('[ChatSoundEffects] playRecordStop error:', e);
    }
  }

  /**
   * Play Trash / Discard Sound
   * Quick swoosh / pitch drop
   */
  playTrash(): void {
    try {
      const ctx = this.getAudioContext();
      if (!ctx) return;

      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'triangle';
      const now = ctx.currentTime;

      osc.frequency.setValueAtTime(380, now);
      osc.frequency.exponentialRampToValueAtTime(120, now + 0.14);

      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(0.15, now + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.15);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.16);
    } catch (e) {
      console.warn('[ChatSoundEffects] playTrash error:', e);
    }
  }

  /**
   * Play Send Confirmation Tone
   * Sweet, gentle upward pop
   */
  playSend(): void {
    try {
      const ctx = this.getAudioContext();
      if (!ctx) return;

      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      const now = ctx.currentTime;

      osc.frequency.setValueAtTime(580, now);
      osc.frequency.exponentialRampToValueAtTime(940, now + 0.07);

      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(0.12, now + 0.015);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.1);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.11);
    } catch (e) {
      console.warn('[ChatSoundEffects] playSend error:', e);
    }
  }

  /**
   * Play Incoming Message / Notification Chime
   * Pleasant dual-tone bell (C5 -> G5)
   */
  playReceive(): void {
    try {
      const ctx = this.getAudioContext();
      if (!ctx) return;

      const now = ctx.currentTime;

      // Note 1: 523Hz (C5)
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(523.25, now);
      gain1.gain.setValueAtTime(0.001, now);
      gain1.gain.linearRampToValueAtTime(0.15, now + 0.02);
      gain1.gain.exponentialRampToValueAtTime(0.0001, now + 0.18);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 0.19);

      // Note 2: 783.99Hz (G5)
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = 'sine';
      osc2.frequency.setValueAtTime(783.99, now + 0.08);
      gain2.gain.setValueAtTime(0.001, now + 0.08);
      gain2.gain.linearRampToValueAtTime(0.18, now + 0.10);
      gain2.gain.exponentialRampToValueAtTime(0.0001, now + 0.35);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now + 0.08);
      osc2.stop(now + 0.36);
    } catch (e) {
      console.warn('[ChatSoundEffects] playReceive error:', e);
    }
  }

  /**
   * Generates a valid standard 16-bit PCM Mono WAV Data URI
   * containing a natural melodic voice-note carrier so playback always works.
   */
  generateWavVoiceNoteDataUrl(durationSeconds: number = 3): string {
    const sampleRate = 8000;
    const numSamples = Math.max(1, Math.round(sampleRate * Math.min(durationSeconds, 60)));
    const blockAlign = 2; // 1 channel * 16-bit
    const byteRate = sampleRate * blockAlign;
    const subChunk2Size = numSamples * blockAlign;
    const chunkSize = 36 + subChunk2Size;

    const buffer = new ArrayBuffer(44 + subChunk2Size);
    const view = new DataView(buffer);

    // RIFF chunk descriptor
    view.setUint8(0, 0x52); // 'R'
    view.setUint8(1, 0x49); // 'I'
    view.setUint8(2, 0x46); // 'F'
    view.setUint8(3, 0x46); // 'F'
    view.setUint32(4, chunkSize, true);
    view.setUint8(8, 0x57);  // 'W'
    view.setUint8(9, 0x41);  // 'A'
    view.setUint8(10, 0x56); // 'V'
    view.setUint8(11, 0x45); // 'E'

    // "fmt " sub-chunk
    view.setUint8(12, 0x66); // 'f'
    view.setUint8(13, 0x6d); // 'm'
    view.setUint8(14, 0x74); // 't'
    view.setUint8(15, 0x20); // ' '
    view.setUint32(16, 16, true); // SubChunk1Size (16 for PCM)
    view.setUint16(20, 1, true);  // AudioFormat (1 = PCM)
    view.setUint16(22, 1, true);  // NumChannels (1 = Mono)
    view.setUint32(24, sampleRate, true); // SampleRate
    view.setUint32(28, byteRate, true);   // ByteRate
    view.setUint16(32, blockAlign, true); // BlockAlign
    view.setUint16(34, 16, true);         // BitsPerSample

    // "data" sub-chunk
    view.setUint8(36, 0x64); // 'd'
    view.setUint8(37, 0x61); // 'a'
    view.setUint8(38, 0x74); // 't'
    view.setUint8(39, 0x61); // 'a'
    view.setUint32(40, subChunk2Size, true);

    // Write samples (vocal harmonic tone pattern)
    let offset = 44;
    for (let i = 0; i < numSamples; i++) {
      const t = i / sampleRate;
      // Melodic speech-like cadence
      const freq = 220 + 35 * Math.sin(2 * Math.PI * 1.5 * t) + 15 * Math.sin(2 * Math.PI * 4 * t);
      const envelope = Math.sin(Math.PI * (i / numSamples)) * 0.4;
      const sample = Math.sin(2 * Math.PI * freq * t) * envelope;
      const int16 = Math.max(-32768, Math.min(32767, Math.floor(sample * 32767)));
      view.setInt16(offset, int16, true);
      offset += 2;
    }

    // Convert ArrayBuffer to Base64
    let binary = '';
    const bytes = new Uint8Array(buffer);
    const len = bytes.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return `data:audio/wav;base64,${typeof btoa !== 'undefined' ? btoa(binary) : ''}`;
  }
}

export const chatSounds = new ChatSoundEffects();
