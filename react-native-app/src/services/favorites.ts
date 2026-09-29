import { useCallback } from 'react';
import { useFavoritesStore } from '../store/useFavoritesStore';

export { useFavoritesStore };

export function useFavorites() {
  const favorites = useFavoritesStore((state) => state.favorites);
  const toggleFavoriteStore = useFavoritesStore((state) => state.toggleFavorite);

  const toggleFavorite = useCallback(async (arg: any) => {
    const partId = typeof arg === 'string' ? arg : (arg?.id || '');
    if (!partId) return;
    await toggleFavoriteStore(partId);
  }, [toggleFavoriteStore]);

  const isFavorited = useCallback((arg: any) => {
    const partId = typeof arg === 'string' ? arg : (arg?.id || '');
    return Boolean(partId && favorites.includes(partId));
  }, [favorites]);

  return { favorites, toggleFavorite, isFavorited };
}

export default useFavorites;


