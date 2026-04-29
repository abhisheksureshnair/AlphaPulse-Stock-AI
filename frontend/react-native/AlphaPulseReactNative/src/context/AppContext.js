import React, { createContext, useContext, useState, useEffect } from 'react';

const AppContext = createContext(undefined);

export const AppProvider = ({ children }) => {
  const [selectedTicker, setSelectedTicker] = useState('AAPL');
  const [trackedSymbols] = useState(['AAPL', 'TSLA', 'NVDA', 'MSFT', 'AMZN']);

  return (
    <AppContext.Provider value={{ selectedTicker, selectTicker: setSelectedTicker, trackedSymbols }}>
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within an AppProvider');
  return context;
};
