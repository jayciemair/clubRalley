import React, { useState } from 'react';
import './ProfileScreen.css';

/* ───────────────────────── DATA ───────────────────────── */

const STATS = [
  { value: 47, label: 'Friends' },
  { value: 25, label: 'Ralleys' },
  { value: 12, label: 'Posts' },
];

const SPORTS = [
  { name: 'AVS Club', level: 'Intermediate', icon: 'volleyball' },
  { name: 'Basketball', level: 'Intermediate', icon: 'basketball' },
  { name: 'Tennis', level: 'Advanced', icon: 'tennis' },
  { name: 'Running', level: 'Beginner', icon: 'running' },
];

const PHOTOS = Array.from({ length: 9 }, (_, i) =>
  `https://picsum.photos/200/200?random=${i + 40}`
);

const MUTUAL_COLORS = ['#a8c4b8', '#7a9e8e', '#5a8070'];

/* ───────────────────────── ICONS ───────────────────────── */

const PinIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
    <circle cx="12" cy="10" r="3" />
  </svg>
);

const GearIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="3" />
    <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" />
  </svg>
);

const SignalIcon = () => (
  <svg width="16" height="12" viewBox="0 0 16 12" fill="#1a1a1a">
    <rect x="0" y="8" width="3" height="4" rx="0.5" />
    <rect x="4.5" y="5" width="3" height="7" rx="0.5" />
    <rect x="9" y="2" width="3" height="10" rx="0.5" />
    <rect x="13.5" y="0" width="2.5" height="12" rx="0.5" opacity="0.3" />
  </svg>
);

const WifiIcon = () => (
  <svg width="16" height="12" viewBox="0 0 16 12" fill="none" stroke="#1a1a1a" strokeWidth="1.6" strokeLinecap="round">
    <path d="M1 3.5C4.5.5 11.5.5 15 3.5" />
    <path d="M3.5 6.5C5.8 4.5 10.2 4.5 12.5 6.5" />
    <path d="M6 9.5C7.2 8.5 8.8 8.5 10 9.5" />
    <circle cx="8" cy="11.5" r="1" fill="#1a1a1a" stroke="none" />
  </svg>
);

const BatteryIcon = () => (
  <svg width="26" height="12" viewBox="0 0 26 12" fill="none">
    <rect x="0.5" y="0.5" width="22" height="11" rx="2.5" stroke="#1a1a1a" strokeWidth="1" />
    <rect x="2" y="2" width="19" height="8" rx="1.5" fill="#1a1a1a" />
    <rect x="23.5" y="3.5" width="2" height="5" rx="1" fill="#1a1a1a" opacity="0.4" />
  </svg>
);

const SportIcon = ({ type }) => {
  const icons = {
    volleyball: (
      <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="1.8" strokeLinecap="round">
        <circle cx="12" cy="12" r="10" />
        <path d="M12 2a15 15 0 014 10 15 15 0 01-4 10" />
        <path d="M2 12h20" />
      </svg>
    ),
    basketball: (
      <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="1.8" strokeLinecap="round">
        <circle cx="12" cy="12" r="10" />
        <path d="M4.93 4.93l14.14 14.14" />
        <path d="M19.07 4.93L4.93 19.07" />
        <path d="M12 2v20" />
        <path d="M2 12h20" />
      </svg>
    ),
    tennis: (
      <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="1.8" strokeLinecap="round">
        <circle cx="12" cy="12" r="10" />
        <path d="M18.36 5.64a9 9 0 01-1.77 12.73" />
        <path d="M5.64 5.64a9 9 0 001.77 12.73" />
      </svg>
    ),
    running: (
      <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="14" cy="4" r="2" />
        <path d="M7 21l3-7 3 2 4-8" />
        <path d="M18 8l-2 4-4-2-3 7" />
      </svg>
    ),
  };
  return icons[type] || icons.volleyball;
};

const TabIcon = ({ name, active }) => {
  const color = active ? '#2C4F40' : '#BBBBBB';
  const icons = {
    home: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill={active ? color : 'none'} stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
        {!active && <polyline points="9 22 9 12 15 12 15 22" />}
      </svg>
    ),
    ralleys: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="11" cy="11" r="8" />
        <line x1="21" y1="21" x2="16.65" y2="16.65" />
      </svg>
    ),
    post: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill={active ? color : 'none'} stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="12" r="10" />
        <line x1="12" y1="8" x2="12" y2="16" />
        <line x1="8" y1="12" x2="16" y2="12" />
      </svg>
    ),
    teams: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M23 21v-2a4 4 0 00-3-3.87" />
        <path d="M16 3.13a4 4 0 010 7.75" />
      </svg>
    ),
    profile: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill={active ? color : 'none'} stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" />
        <circle cx="12" cy="7" r="4" />
      </svg>
    ),
  };
  return icons[name] || null;
};

/* ───────────────────────── COMPONENT ───────────────────────── */

export default function ProfileScreen() {
  const [activeTab, setActiveTab] = useState('profile');

  const tabs = [
    { key: 'home', label: 'Home' },
    { key: 'ralleys', label: 'Ralleys' },
    { key: 'post', label: 'Post' },
    { key: 'teams', label: 'Teams' },
    { key: 'profile', label: 'Profile' },
  ];

  return (
    <div className="phone-shell">
      <div className="screen">
        {/* ── Status Bar ── */}
        <div className="status-bar">
          <span className="status-time">9:41</span>
          <div className="status-icons">
            <SignalIcon />
            <WifiIcon />
            <BatteryIcon />
          </div>
        </div>

        {/* ── Top Bar ── */}
        <div className="top-bar">
          <div className="top-bar-location">
            <PinIcon />
            <span>Chicago, IL</span>
          </div>
          <button className="top-bar-gear" aria-label="Settings">
            <GearIcon />
          </button>
        </div>

        {/* ── Scrollable Content ── */}
        <div className="scroll-content">
          {/* Avatar */}
          <div className="avatar-wrapper">
            <div className="avatar-circle">
              {/* Replace with <img src="..." /> for real photo */}
              <span className="avatar-initials">GK</span>
            </div>
          </div>

          {/* Name & Username */}
          <h1 className="profile-name">Gracie King</h1>
          <p className="profile-username">@gracieking</p>

          {/* Stats Row */}
          <div className="stats-row">
            {STATS.map((stat, i) => (
              <React.Fragment key={stat.label}>
                {i > 0 && <div className="stat-divider" />}
                <div className="stat-cell">
                  <span className="stat-value">{stat.value}</span>
                  <span className="stat-label">{stat.label}</span>
                </div>
              </React.Fragment>
            ))}
          </div>

          {/* Bio */}
          <p className="bio">
            Former D1 tennis player at <strong>Bucknell University</strong> / Class of 2025
          </p>

          {/* Mutual Friends */}
          <div className="mutual-friends">
            <div className="mutual-avatars">
              {MUTUAL_COLORS.map((color, i) => (
                <div
                  key={i}
                  className="mutual-avatar"
                  style={{
                    backgroundColor: color,
                    zIndex: 3 - i,
                    marginLeft: i === 0 ? 0 : -8,
                  }}
                />
              ))}
            </div>
            <span className="mutual-text">
              Friends with <strong>sammarcus</strong>, <strong>jaycieabby</strong>, and <strong>5 others</strong>
            </span>
          </div>

          {/* Edit Profile Button */}
          <button className="edit-profile-btn">Edit Profile</button>

          {/* Hairline Divider */}
          <div className="hairline-divider" />

          {/* My Sports Section */}
          <div className="section">
            <div className="section-header">
              <span className="section-pill">My Sports</span>
              <span className="show-all">Show All</span>
            </div>
            <div className="sports-scroll">
              {SPORTS.map((sport) => (
                <div key={sport.name} className="sport-card">
                  <div className="sport-icon-circle">
                    <SportIcon type={sport.icon} />
                  </div>
                  <span className="sport-name">{sport.name}</span>
                  <span className="sport-level">{sport.level}</span>
                </div>
              ))}
            </div>
          </div>

          {/* My Pics Section */}
          <div className="section">
            <div className="section-header">
              <span className="section-pill">My Pics</span>
              <span className="show-all">Show All</span>
            </div>
            <div className="photos-grid">
              {PHOTOS.map((url, i) => (
                <div key={i} className="photo-cell">
                  <img src={url} alt="" loading="lazy" />
                </div>
              ))}
            </div>
          </div>

          {/* Bottom spacer for tab bar */}
          <div style={{ height: 80 }} />
        </div>

        {/* ── Tab Bar ── */}
        <div className="tab-bar">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              className={`tab-btn ${activeTab === tab.key ? 'tab-active' : ''}`}
              onClick={() => setActiveTab(tab.key)}
            >
              <TabIcon name={tab.key} active={activeTab === tab.key} />
              <span className="tab-label">{tab.label}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
