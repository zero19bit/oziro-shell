import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './styles/tokens.css';
import './styles/shell.css';
import './styles/shared.css';
import './styles/dock.css';
import './styles/launcher.css';
import './styles/control.css';
import './styles/settings.css';
import './styles/notifications.css';
import './styles/overview.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
