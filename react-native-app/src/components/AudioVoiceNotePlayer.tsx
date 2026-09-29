import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Animated, Platform } from 'react-native';
import { Icon } from 'react-native-paper';

interface AudioVoiceNotePlayerProps {
  durationText?: string;
  isMe?: boolean;
  audioUrl?: string | null;
}

export const AudioVoiceNotePlayer: React.FC<AudioVoiceNotePlayerProps> = ({
  durationText = '0:05',
  isMe = false,
  audioUrl = null,
}) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [currentPlaybackTime, setCurrentPlaybackTime] = useState<string | null>(null);

  const audioRef = useRef<any>(null);
  const timerRef = useRef<any>(null);

  const waveAnims = useRef(
    [0.4, 0.8, 0.5, 0.9, 0.3, 0.7, 1.0, 0.6, 0.4, 0.8].map((init) => new Animated.Value(init))
  ).current;

  // Cleanup audio and timer on unmount
  useEffect(() => {
    return () => {
      if (audioRef.current) {
        try {
          audioRef.current.pause();
          audioRef.current = null;
        } catch (_) {}
      }
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, []);

  useEffect(() => {
    if (isPlaying) {
      // Animate wave bars
      waveAnims.forEach((anim) => {
        Animated.loop(
          Animated.sequence([
            Animated.timing(anim, {
              toValue: Math.random() * 0.8 + 0.2,
              duration: 250,
              useNativeDriver: true,
            }),
            Animated.timing(anim, {
              toValue: Math.random() * 0.8 + 0.2,
              duration: 250,
              useNativeDriver: true,
            }),
          ])
        ).start();
      });
    } else {
      waveAnims.forEach((anim, i) => {
        anim.stopAnimation();
        anim.setValue([0.4, 0.8, 0.5, 0.9, 0.3, 0.7, 1.0, 0.6, 0.4, 0.8][i]);
      });
    }
  }, [isPlaying]);

  const togglePlay = () => {
    if (isPlaying) {
      // Pause
      if (audioRef.current) {
        try {
          audioRef.current.pause();
        } catch (_) {}
      }
      if (timerRef.current) clearInterval(timerRef.current);
      setIsPlaying(false);
    } else {
      // Start Playing
      if (audioUrl && typeof window !== 'undefined' && (window as any).Audio) {
        try {
          if (!audioRef.current || audioRef.current.src !== audioUrl) {
            const audio = new (window as any).Audio(audioUrl);
            audioRef.current = audio;

            audio.onended = () => {
              setIsPlaying(false);
              setProgress(0);
              setCurrentPlaybackTime(null);
              if (timerRef.current) clearInterval(timerRef.current);
            };

            audio.ontimeupdate = () => {
              if (audio.duration && !isNaN(audio.duration) && audio.duration > 0) {
                const pct = (audio.currentTime / audio.duration) * 100;
                setProgress(Math.min(pct, 100));
                const remaining = Math.max(0, Math.ceil(audio.duration - audio.currentTime));
                const remM = Math.floor(remaining / 60);
                const remS = remaining % 60;
                setCurrentPlaybackTime(`${remM}:${remS < 10 ? '0' : ''}${remS}`);
              }
            };

            audio.onerror = (e: any) => {
              console.warn('[AudioVoiceNotePlayer] Playback error:', e);
              setIsPlaying(false);
            };
          }

          audioRef.current.play().then(() => {
            setIsPlaying(true);
          }).catch((err: any) => {
            console.warn('[AudioVoiceNotePlayer] audio.play() failed:', err);
            // Fallback to simulated playback
            startSimulatedPlayback();
          });
          return;
        } catch (e) {
          console.warn('[AudioVoiceNotePlayer] Error creating audio element:', e);
        }
      }

      startSimulatedPlayback();
    }
  };

  const startSimulatedPlayback = () => {
    setIsPlaying(true);
    setProgress(0);
    let currentPct = 0;
    if (timerRef.current) clearInterval(timerRef.current);
    timerRef.current = setInterval(() => {
      currentPct += 15;
      if (currentPct >= 100) {
        setIsPlaying(false);
        setProgress(0);
        setCurrentPlaybackTime(null);
        if (timerRef.current) clearInterval(timerRef.current);
      } else {
        setProgress(currentPct);
      }
    }, 500);
  };

  const activeColor = isMe ? '#FFFFFF' : '#0066FF';
  const inactiveColor = isMe ? 'rgba(255, 255, 255, 0.4)' : '#CBD5E1';

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={[styles.playBtn, { backgroundColor: activeColor }]}
        onPress={togglePlay}
        activeOpacity={0.8}
      >
        <Icon
          source={isPlaying ? 'pause' : 'play'}
          size={20}
          color={isMe ? '#0066FF' : '#FFFFFF'}
        />
      </TouchableOpacity>

      <View style={styles.waveContainer}>
        <View style={styles.barsRow}>
          {waveAnims.map((anim, idx) => (
            <Animated.View
              key={`wave-${idx}`}
              style={[
                styles.waveBar,
                {
                  height: 18,
                  backgroundColor: isPlaying && (idx * 10 < progress) ? activeColor : inactiveColor,
                  transform: [{ scaleY: anim }],
                },
              ]}
            />
          ))}
        </View>

        <View style={styles.footerRow}>
          <Text style={[styles.durationText, { color: isMe ? 'rgba(255,255,255,0.85)' : '#64748B' }]}>
            {isPlaying && currentPlaybackTime ? currentPlaybackTime : durationText}
          </Text>
          <Icon source="microphone" size={13} color={isMe ? '#93C5FD' : '#3B82F6'} />
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    minWidth: 175,
    paddingVertical: 4,
  },
  playBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
    elevation: 2,
  },
  waveContainer: {
    flex: 1,
  },
  barsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    height: 22,
    marginBottom: 2,
  },
  waveBar: {
    width: 3,
    borderRadius: 2,
  },
  footerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  durationText: {
    fontSize: 11.5,
    fontWeight: '700',
  },
});

