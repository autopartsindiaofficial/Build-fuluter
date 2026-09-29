import { create } from 'zustand';

export interface FilterState {
  searchQuery: string;
  selectedCategory: string;
  selectedBrand: string;
  minPrice: number | null;
  maxPrice: number | null;
  condition: string | null;
  sortBy: 'latest' | 'price_low' | 'price_high' | 'distance';
  setSearchQuery: (query: string) => void;
  setSelectedCategory: (category: string) => void;
  setSelectedBrand: (brand: string) => void;
  setPriceRange: (min: number | null, max: number | null) => void;
  setCondition: (condition: string | null) => void;
  setSortBy: (sortBy: 'latest' | 'price_low' | 'price_high' | 'distance') => void;
  resetFilters: () => void;
}

const INITIAL_STATE = {
  searchQuery: '',
  selectedCategory: 'All',
  selectedBrand: 'All',
  minPrice: null,
  maxPrice: null,
  condition: null,
  sortBy: 'latest' as const,
};

export const useFilterStore = create<FilterState>((set) => ({
  ...INITIAL_STATE,

  setSearchQuery: (searchQuery) => set({ searchQuery }),
  setSelectedCategory: (selectedCategory) => set({ selectedCategory }),
  setSelectedBrand: (selectedBrand) => set({ selectedBrand }),
  setPriceRange: (minPrice, maxPrice) => set({ minPrice, maxPrice }),
  setCondition: (condition) => set({ condition }),
  setSortBy: (sortBy) => set({ sortBy }),
  resetFilters: () => set(INITIAL_STATE),
}));
