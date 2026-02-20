import { useState } from "react";

// ── Data ──────────────────────────────────────────────────────────────────────

const sportOptions = ["Soccer","Tennis","Basketball","Running","CrossFit","Swimming","Pickleball","Volleyball"];

const posts = [
  {
    id: 1,
    user: "Gracie King",
    bio: "Former D1 tennis player at Bucknell University",
    time: "Today",
    location: "Chicago, IL",
    initials: "GK",
    avatarColor: "#3d7a62",
    sport: "Tennis",
    title: "Tennis Club Event",
    text: "Just played my first game at Ralley sponsored rec-league Chicago sports!",
    mutualText: "& your friends loved this post",
    mutualColors: ["#a8c4b8", "#7a9e8e"],
    likes: 24,
    comments: 6,
    photos: [
      "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80",
      "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80",
      "https://images.unsplash.com/photo-1504025468847-0e438279542c?w=400&q=80",
      "https://images.unsplash.com/photo-1517466787929-bc90951d0974?w=400&q=80",
      "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80",
    ],
  },
  {
    id: 2,
    user: "Ryan Smith",
    bio: "Former D1 soccer player at Texas A&M",
    time: "Today",
    location: "Chicago, IL",
    initials: "RS",
    avatarColor: "#5a7fa0",
    sport: "Tennis",
    title: "Tennis Match",
    text: "I need a hitting partner for tomorrow afternoon. Send help!",
    mutualText: "3 mutual teammates",
    mutualColors: ["#a8c4b8", "#7a9e8e", "#5a8070"],
    likes: 11,
    comments: 3,
    photos: [],
  },
  {
    id: 3,
    user: "Gracie King",
    bio: "Former D1 tennis player at Bucknell University",
    time: "1 day ago",
    location: "Chicago, IL",
    initials: "GK",
    avatarColor: "#3d7a62",
    sport: "Tennis",
    title: "Tennis Match",
    text: "Just finished two sets with my bestie!",
    mutualText: "& your friends loved this post",
    mutualColors: ["#a8c4b8", "#7a9e8e"],
    likes: 38,
    comments: 9,
    photos: [
      "https://images.unsplash.com/photo-1594623274890-6b45ce7cf44a?w=400&q=80",
      "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80",
    ],
  },
];

// ── Icons ─────────────────────────────────────────────────────────────────────

const HomeIcon   = ({on}) => <svg width="24" height="24" viewBox="0 0 24 24" fill={on?"#2C4F40":"none"} stroke={on?"#2C4F40":"#bbb"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9.5L12 3l9 6.5V20a1 1 0 01-1 1H4a1 1 0 01-1-1V9.5z"/><path d="M9 21V12h6v9" stroke={on?"#2C4F40":"#bbb"} strokeWidth="2"/></svg>;
const SearchIcon = ({on}) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={on?"#2C4F40":"#bbb"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>;
const TeamsIcon  = ({on}) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={on?"#2C4F40":"#bbb"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>;
const PersonIcon = ({on}) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={on?"#2C4F40":"#bbb"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>;
const PlusIcon   = () => <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>;
const BellIcon   = () => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>;
const ImageIcon  = () => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>;
const TagIcon    = () => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/><circle cx="7" cy="7" r="1"/></svg>;

const HeartIcon  = ({filled}) => <svg width="19" height="19" viewBox="0 0 24 24" fill={filled?"#e74c3c":"none"} stroke={filled?"#e74c3c":"#aaa"} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z"/></svg>;
const RepostIcon = () => <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#aaa" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M17 1l4 4-4 4"/><path d="M3 11V9a4 4 0 014-4h14"/><path d="M7 23l-4-4 4-4"/><path d="M21 13v2a4 4 0 01-4 4H3"/></svg>;
const CommentIcon= () => <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#aaa" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>;
const ShareIcon  = () => <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="#aaa" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.59 13.51l6.83 3.98M15.41 6.51l-6.82 3.98"/></svg>;
const LocationPinIcon = ({size=13, color="#2C4F40"}) => <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>;

// ── Sport Icons ───────────────────────────────────────────────────────────────

const SportIcon = ({ sport, size = 13, color = "currentColor" }) => {
  const s = { width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: color, strokeWidth: 2, strokeLinecap: "round", strokeLinejoin: "round" };
  const icons = {
    Tennis:     <svg {...s}><ellipse cx="12" cy="12" rx="10" ry="10"/><path d="M5.5 5.5C8 8 8 16 5.5 18.5"/><path d="M18.5 5.5C16 8 16 16 18.5 18.5"/></svg>,
    Soccer:     <svg {...s}><circle cx="12" cy="12" r="10"/><path d="M12 2v4M12 18v4M2 12h4M18 12h4"/><path d="M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8"/></svg>,
    Basketball: <svg {...s}><circle cx="12" cy="12" r="10"/><path d="M4.9 4.9C8 8 8 16 4.9 19.1"/><path d="M19.1 4.9C16 8 16 16 19.1 19.1"/><path d="M2 12h20"/><path d="M12 2v20"/></svg>,
    Running:    <svg {...s}><circle cx="12" cy="5" r="2"/><path d="M10 22l1-6-3-2 2-5 4 2 2-4"/><path d="M17 8l-3 1"/></svg>,
    CrossFit:   <svg {...s}><path d="M12 2v20M2 12h20"/><path d="M5 5l14 14M19 5L5 19"/></svg>,
    Swimming:   <svg {...s}><path d="M2 12c1.5-2 3-2 4.5 0s3 2 4.5 0 3-2 4.5 0 3 2 4.5 0"/><path d="M2 17c1.5-2 3-2 4.5 0s3 2 4.5 0 3-2 4.5 0 3 2 4.5 0"/><path d="M15 4l-3 4 4 2"/></svg>,
    Pickleball: <svg {...s}><circle cx="12" cy="12" r="10"/><circle cx="9" cy="9" r="1.5" fill={color} stroke="none"/><circle cx="15" cy="9" r="1.5" fill={color} stroke="none"/><circle cx="9" cy="15" r="1.5" fill={color} stroke="none"/><circle cx="15" cy="15" r="1.5" fill={color} stroke="none"/></svg>,
    Volleyball: <svg {...s}><circle cx="12" cy="12" r="10"/><path d="M12 2C8 6 8 18 12 22"/><path d="M2 12c4-4 16-4 20 0"/><path d="M4.9 4.9c3 6 11 6 14.2 0"/></svg>,
  };
  return icons[sport] || <svg {...s}><circle cx="12" cy="12" r="10"/><path d="M12 8v4l3 3"/></svg>;
};

// ── Photo Collage ─────────────────────────────────────────────────────────────

function PhotoCollage({ photos }) {
  if (!photos || photos.length === 0) return null;
  if (photos.length === 1) return <img src={photos[0]} style={{ width:"100%", height:240, objectFit:"cover", display:"block" }} alt="" />;
  if (photos.length === 2) return (
    <div style={{ display:"flex", gap:2 }}>
      {photos.map((p,i) => <img key={i} src={p} style={{ flex:1, height:210, objectFit:"cover", display:"block" }} alt="" />)}
    </div>
  );
  return (
    <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gridTemplateRows:"145px 145px", gap:2 }}>
      <img src={photos[0]} style={{ gridColumn:"1", gridRow:"1", width:"100%", height:"100%", objectFit:"cover" }} alt="" />
      <div style={{ gridColumn:"2", gridRow:"1 / 3", display:"flex", flexDirection:"column", gap:2 }}>
        <img src={photos[1]} style={{ flex:1, width:"100%", objectFit:"cover" }} alt="" />
        {photos[2] && <img src={photos[2]} style={{ flex:1, width:"100%", objectFit:"cover" }} alt="" />}
      </div>
      {(photos[3] || photos[4]) && (
        <div style={{ gridColumn:"1", gridRow:"2", display:"flex", gap:2 }}>
          {photos[3] && <img src={photos[3]} style={{ flex:1, objectFit:"cover", height:"100%" }} alt="" />}
          {photos[4] && <img src={photos[4]} style={{ flex:1, objectFit:"cover", height:"100%" }} alt="" />}
        </div>
      )}
    </div>
  );
}

// ── Home Screen ───────────────────────────────────────────────────────────────

function HomeScreen() {
  const upcomingRalleys = [
    { id:1, sport:"Pickleball", title:"Pickleball at Bucknell Turf", date:"Thu, Feb 19 at 6:45 PM", location:"Bucknell Turf Fields", joined:1, total:4, countdown:"in 11m" },
    { id:2, sport:"Soccer", title:"Sunday Pickup Soccer", date:"Sun, Feb 22 at 10:00 AM", location:"Millennium Park", joined:3, total:10, countdown:"in 3d" },
  ];

  return (
    <div className="screen-body" style={{ background:"#f6f5f1" }}>
      {/* Topbar: Your Upcoming Ralleys label + bell */}
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", padding:"10px 22px 4px" }}>
        <div style={{ display:"flex", alignItems:"center", gap:7 }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg>
          <span style={{ fontFamily:"'Chillax', sans-serif", fontSize:22, fontWeight:700, color:"#2C4F40", letterSpacing:"-0.3px" }}>Your Upcoming Ralleys</span>
        </div>
        <div style={{ position:"relative", cursor:"pointer" }}>
          <BellIcon />
          <div className="notif-dot" />
        </div>
      </div>

      {/* Upcoming scroll cards */}
      <div style={{ display:"flex", overflowX:"auto", gap:10, padding:"10px 22px 18px", scrollbarWidth:"none" }}>
        {upcomingRalleys.map(r => (
          <div key={r.id} style={{
            background:"#2C4F40", borderRadius:16, padding:"14px 16px",
            minWidth:230, flexShrink:0,
            boxShadow:"0 6px 24px rgba(44,79,64,0.25)",
          }}>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:8 }}>
              <div style={{ display:"inline-flex", alignItems:"center", gap:5, background:"rgba(255,255,255,0.18)", color:"white", fontFamily:"'DM Sans', sans-serif", fontSize:11, fontWeight:700, padding:"3px 10px", borderRadius:50 }}>
                <SportIcon sport={r.sport} size={11} color="white" /> {r.sport}
              </div>
              <div style={{ background:"rgba(255,255,255,0.18)", color:"white", fontFamily:"'DM Sans', sans-serif", fontSize:11, fontWeight:700, padding:"3px 10px", borderRadius:50 }}>
                {r.countdown}
              </div>
            </div>
            <div style={{ fontFamily:"'Chillax', sans-serif", fontSize:16, fontWeight:700, color:"white", marginBottom:8, lineHeight:1.25 }}>
              {r.title}
            </div>
            <div style={{ display:"flex", flexDirection:"column", gap:4 }}>
              {[
                { icon:<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.65)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>, text:r.date },
                { icon:<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.65)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>, text:r.location },
                { icon:<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.65)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>, text:`${r.joined}/${r.total} joined` },
              ].map(({ icon, text }, i) => (
                <div key={i} style={{ display:"flex", alignItems:"center", gap:5, fontFamily:"'DM Sans', sans-serif", fontSize:11, fontWeight:600, color:"rgba(255,255,255,0.65)" }}>
                  {icon} {text}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Warm divider */}
      <div style={{ height:6, background:"linear-gradient(to bottom, #e8e5de, #ece9e2)", margin:"4px 0" }} />

      {/* Activity section header */}
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", padding:"18px 22px 4px" }}>
        <div style={{ display:"flex", alignItems:"center", gap:7 }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2C4F40" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
          <span style={{ fontFamily:"'Chillax', sans-serif", fontSize:20, fontWeight:700, color:"#2C4F40", letterSpacing:"-0.3px" }}>Activity</span>
        </div>
        <span style={{ fontFamily:"'DM Sans', sans-serif", fontSize:13, fontWeight:800, color:"#2C4F40" }}>See all</span>
      </div>

      {posts.map((p, idx) => (
        <FriendPost key={p.id} post={p} idx={idx} />
      ))}
    </div>
  );
}

// ── Friend Post ───────────────────────────────────────────────────────────────

function FriendPost({ post: p, idx }) {
  const [liked, setLiked] = useState(false);
  const [likeCount, setLikeCount] = useState(p.likes || 0);

  const handleLike = () => {
    setLiked(l => !l);
    setLikeCount(c => liked ? c - 1 : c + 1);
  };

  return (
    <div>
      {idx > 0 && <div style={{ height:8, background:"#ece9e2" }} />}
      <div style={{ padding:"16px 22px 0", background:"#f6f5f1" }}>
        {/* Header */}
        <div style={{ display:"flex", gap:12, alignItems:"center", marginBottom:12 }}>
          <div style={{ width:46, height:46, borderRadius:"50%", background: p.avatarColor || "#2C4F40", display:"flex", alignItems:"center", justifyContent:"center", fontFamily:"'DM Sans', sans-serif", fontSize:14, fontWeight:900, color:"#fff", flexShrink:0, boxShadow:"0 2px 8px rgba(0,0,0,0.12)" }}>
            {p.initials}
          </div>
          <div style={{ flex:1 }}>
            <div style={{ display:"flex", alignItems:"center", gap:6, flexWrap:"wrap" }}>
              <span style={{ fontFamily:"'DM Sans', sans-serif", fontSize:16, fontWeight:800, color:"#2C4F40" }}>{p.user}</span>
              {p.sport && (
                <span style={{ display:"inline-flex", alignItems:"center", gap:4, background:"#E2E4D6", color:"#2C4F40", fontFamily:"'DM Sans', sans-serif", fontSize:10.5, fontWeight:800, padding:"2px 8px", borderRadius:50 }}>
                  <SportIcon sport={p.sport} size={10} color="#2C4F40" /> {p.sport}
                </span>
              )}
            </div>
            <div style={{ fontFamily:"'DM Sans', sans-serif", fontSize:12, fontWeight:600, color:"rgba(44,79,64,0.55)", marginTop:2, display:"flex", alignItems:"center", gap:3 }}>
              {p.time} · <LocationPinIcon size={10} color="rgba(44,79,64,0.55)" /> {p.location}
            </div>
          </div>
          <button style={{ background:"none", border:"none", cursor:"pointer", padding:4, color:"#ccc" }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="#ccc"><circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/></svg>
          </button>
        </div>

        {p.title && <div style={{ fontFamily:"'Chillax', sans-serif", fontSize:16, fontWeight:700, color:"#2C4F40", marginBottom:4 }}>{p.title}</div>}
        {p.text  && <div style={{ fontFamily:"'DM Sans', sans-serif", fontSize:14, fontWeight:500, color:"rgba(44,79,64,0.7)", lineHeight:1.6, marginBottom:14 }}>{p.text}</div>}

        {p.photos.length > 0 && (
          <div style={{ margin:"0 -22px", marginBottom:0 }}><PhotoCollage photos={p.photos} /></div>
        )}

        {p.mutualText && (
          <div style={{ display:"flex", alignItems:"center", padding:"10px 0 2px" }}>
            <div style={{ display:"flex" }}>
              {p.mutualColors.map((c,i) => <div key={i} style={{ width:18, height:18, borderRadius:"50%", background:c, border:"2px solid #f6f5f1", marginRight:-5 }} />)}
            </div>
            <span style={{ fontFamily:"'DM Sans', sans-serif", fontSize:11, fontWeight:600, color:"#9aaa9f", marginLeft:10 }}>{p.mutualText}</span>
          </div>
        )}

        {/* Actions */}
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", padding:"10px 0 14px", borderTop:"1px solid #ece9e2", marginTop:10 }}>
          <button onClick={handleLike} style={{ background:"none", border:"none", cursor:"pointer", padding:0, display:"flex", alignItems:"center", gap:5 }}>
            <HeartIcon filled={liked} />
            <span style={{ fontFamily:"'DM Sans', sans-serif", fontSize:12, fontWeight:700, color: liked ? "#e74c3c" : "#bbb" }}>{likeCount}</span>
          </button>
          <button style={{ background:"none", border:"none", cursor:"pointer", padding:0, display:"flex", alignItems:"center", gap:5 }}>
            <CommentIcon />
            <span style={{ fontFamily:"'DM Sans', sans-serif", fontSize:12, fontWeight:700, color:"#bbb" }}>{p.comments || 0}</span>
          </button>
          <button style={{ background:"none", border:"none", cursor:"pointer", padding:0 }}><RepostIcon /></button>
          <button style={{ background:"none", border:"none", cursor:"pointer", padding:0 }}><ShareIcon /></button>
        </div>
      </div>
    </div>
  );
}

// ── Post Composer ─────────────────────────────────────────────────────────────

function CharRing({ count, max }) {
  const pct = Math.min(count / max, 1);
  const r = 9;
  const circ = 2 * Math.PI * r;
  const dash = pct * circ;
  const over = count > max;
  const warn = count > max * 0.9;
  const color = over ? "#e74c3c" : warn ? "#f39c12" : "#2C4F40";
  return (
    <svg width="24" height="24" viewBox="0 0 24 24">
      <circle cx="12" cy="12" r={r} fill="none" stroke="#e8e5de" strokeWidth="2.5"/>
      <circle cx="12" cy="12" r={r} fill="none" stroke={color} strokeWidth="2.5"
        strokeDasharray={`${dash} ${circ}`} strokeLinecap="round"
        transform="rotate(-90 12 12)"/>
      {over && <text x="12" y="16" textAnchor="middle" fontSize="8" fontWeight="900" fill="#e74c3c">{count - max}</text>}
    </svg>
  );
}

function PostComposer({ onClose, onPost }) {
  const [text, setText] = useState("");
  const [selectedSport, setSelectedSport] = useState(null);
  const [posted, setPosted] = useState(false);
  const MAX = 280;
  const canPost = (text.trim() || selectedSport) && text.length <= MAX;

  const handlePost = () => {
    if (!canPost) return;
    if (onPost) onPost({ text, sport: selectedSport });
    setPosted(true);
  };

  if (posted) return (
    <div className="screen-body" style={{ alignItems:"center", justifyContent:"center", display:"flex", flexDirection:"column", gap:16, paddingTop:120 }}>
      <div style={{ fontSize:56 }}>🎉</div>
      <div style={{ fontFamily:"'Chillax', sans-serif", fontSize:22, fontWeight:700, color:"#2C4F40" }}>Posted!</div>
      <div style={{ fontFamily:"'DM Sans', sans-serif", fontSize:14, fontWeight:500, color:"#7a8a81", textAlign:"center", padding:"0 40px", lineHeight:1.6 }}>Your post is live on your profile and in your friends' feeds.</div>
      <button className="join-btn" style={{ marginTop:8, width:"auto", padding:"12px 36px", borderRadius:50 }} onClick={onClose}>Back to Home</button>
    </div>
  );

  return (
    <div className="screen-body">
      {/* Header */}
      <div className="composer-hdr">
        <button className="cancel-btn" onClick={onClose}>Cancel</button>
        <span className="composer-title">New Post</span>
        <button
          className={`post-btn ${canPost ? "active" : ""}`}
          onClick={handlePost}
          disabled={!canPost}
        >Post</button>
      </div>

      {/* Avatar + text input */}
      <div className="composer-input-row">
        <div className="c-avatar">JM</div>
        <textarea
          className="composer-textarea"
          placeholder="What did you play today?"
          value={text}
          onChange={e => setText(e.target.value)}
          rows={5}
        />
      </div>

      {/* Tag a sport */}
      <div className="composer-section-label">Tag a Sport</div>
      <div className="sport-tags">
        {sportOptions.map(s => (
          <button
            key={s}
            className={`sport-tag ${selectedSport === s ? "selected" : ""}`}
            onClick={() => setSelectedSport(sel => sel === s ? null : s)}
          >
            <SportIcon sport={s} size={12} color={selectedSport === s ? "#fff" : "#2C4F40"} /> {s}
          </button>
        ))}
      </div>

      {/* Attachments */}
      <div className="composer-section-label">Add to your post</div>
      <div className="attachment-row">
        <button className="attach-btn">
          <div className="attach-icon-wrap"><ImageIcon /></div>
          <span>Photo</span>
        </button>
        <button className="attach-btn">
          <div className="attach-icon-wrap"><TagIcon /></div>
          <span>Tag Players</span>
        </button>
        <button className="attach-btn">
          <div className="attach-icon-wrap"><LocationPinIcon size={22} /></div>
          <span>Location</span>
        </button>
      </div>

      {/* Footer: char count ring + remaining */}
      <div style={{ display:"flex", alignItems:"center", justifyContent:"flex-end", gap:8, padding:"4px 20px 16px" }}>
        {text.length > 0 && (
          <span style={{ fontFamily:"'DM Sans', sans-serif", fontSize:11, fontWeight:600, color: text.length > MAX ? "#e74c3c" : "#bbb" }}>
            {MAX - text.length}
          </span>
        )}
        <CharRing count={text.length} max={MAX} />
      </div>
    </div>
  );
}

// ── Placeholder screens ──────────────────────────────────────────────────────

function PlaceholderScreen({ label, tabIcon }) {
  return (
    <div className="screen-body placeholder-screen">
      <div style={{ width:56, height:56, borderRadius:"50%", background:"#E2E4D6", display:"flex", alignItems:"center", justifyContent:"center", marginBottom:14 }}>
        {tabIcon}
      </div>
      <div style={{ fontFamily:"var(--font)", fontSize:18, fontWeight:900, color:"var(--green)" }}>{label}</div>
      <div style={{ fontFamily:"var(--font)", fontSize:13, fontWeight:600, color:"var(--muted)", marginTop:6 }}>Coming soon</div>
    </div>
  );
}

// ── Root App ──────────────────────────────────────────────────────────────────

export default function App() {
  const [activeTab, setActiveTab] = useState("home");

  const tabs = [
    { id:"home",    label:"Home",    icon: (on) => <HomeIcon on={on}/> },
    { id:"ralleys", label:"Ralleys", icon: (on) => <SearchIcon on={on}/> },
    { id:"post",    label:"",        icon: () => (
      <div style={{ width:48, height:48, borderRadius:"50%", background:"#2C4F40", display:"flex", alignItems:"center", justifyContent:"center", marginTop:-20, boxShadow:"0 4px 16px rgba(44,79,64,0.35)" }}>
        <PlusIcon />
      </div>
    )},
    { id:"teams",   label:"Teams",   icon: (on) => <TeamsIcon on={on}/> },
    { id:"profile", label:"Profile", icon: (on) => <PersonIcon on={on}/> },
  ];

  return (
    <div style={{ minHeight:"100vh", background:"#E2E4D6", display:"flex", justifyContent:"center", alignItems:"flex-start" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700;800;900&display=swap');
        @import url('https://api.fontshare.com/v2/css?f[]=chillax@200,300,400,500,600,700&display=swap');

        * { box-sizing:border-box; margin:0; padding:0; }
        :root {
          --green:#2C4F40; --sage:#E2E4D6; --bg:#f6f5f1;
          --white:#ffffff; --muted:#7a8a81; --border:#e4e4e4;
          --font:'DM Sans', sans-serif;
        }

        .phone {
          width:390px; min-height:844px; background:var(--bg);
          position:relative; overflow:hidden; border-radius:50px;
          box-shadow:0 30px 90px rgba(44,79,64,0.2),0 0 0 1px rgba(0,0,0,0.06);
          margin:40px 0;
        }

        .status {
          display:flex; justify-content:space-between; align-items:center;
          padding:16px 28px 8px;
          font-family:var(--font); font-size:15px; font-weight:800; color:#000;
        }
        .status-r { display:flex; gap:6px; align-items:center; }

        .screen-body {
          overflow-y:auto;
          height:calc(844px - 58px - 72px);
          padding-bottom:24px;
        }
        .screen-body::-webkit-scrollbar { display:none; }

        .notif-dot { width:7px; height:7px; border-radius:50%; background:#e74c3c; border:1.5px solid var(--bg); position:absolute; top:-1px; right:-1px; }

        .join-btn {
          width:100%; padding:11px; border-radius:12px;
          background:var(--green); color:#fff;
          font-family:var(--font); font-size:13px; font-weight:800;
          border:none; cursor:pointer; transition:all 0.15s;
        }

        .placeholder-screen { display:flex; flex-direction:column; align-items:center; justify-content:center; padding-top:140px; }

        .composer-hdr {
          display:flex; align-items:center; justify-content:space-between;
          padding:16px 20px 14px;
          border-bottom:1px solid var(--border);
        }
        .composer-title { font-family:var(--font); font-size:16px; font-weight:900; color:#000; }
        .cancel-btn { font-family:var(--font); font-size:14px; font-weight:700; color:var(--muted); background:none; border:none; cursor:pointer; }
        .post-btn {
          font-family:var(--font); font-size:14px; font-weight:800;
          padding:7px 18px; border-radius:50px;
          background:var(--sage); color:#aaa;
          border:none; cursor:not-allowed; transition:all 0.15s;
        }
        .post-btn.active { background:var(--green); color:#fff; cursor:pointer; }

        .composer-input-row {
          display:flex; gap:12px; padding:16px 20px;
          border-bottom:1px solid var(--border);
        }
        .c-avatar {
          width:42px; height:42px; border-radius:50%;
          background:var(--green); color:#fff;
          display:flex; align-items:center; justify-content:center;
          font-family:var(--font); font-size:13px; font-weight:900;
          flex-shrink:0;
        }
        .composer-textarea {
          flex:1; border:none; background:transparent; resize:none; outline:none;
          font-family:var(--font); font-size:15px; font-weight:500; color:#000;
          line-height:1.55; padding-top:6px;
        }
        .composer-textarea::placeholder { color:#bbb; }

        .composer-section-label {
          font-family:var(--font); font-size:12px; font-weight:800;
          color:var(--muted); text-transform:uppercase; letter-spacing:0.05em;
          padding:14px 20px 8px;
        }

        .sport-tags { display:flex; flex-wrap:wrap; gap:8px; padding:0 20px 16px; }
        .sport-tag {
          font-family:var(--font); font-size:12.5px; font-weight:700;
          padding:6px 14px; border-radius:50px;
          background:var(--sage); color:#555;
          border:none; cursor:pointer; transition:all 0.15s;
          display:inline-flex; align-items:center; gap:5px;
        }
        .sport-tag.selected { background:var(--green); color:#fff; }

        .attachment-row {
          display:flex; gap:0;
          padding:0 20px 16px;
          border-top:1px solid var(--border); padding-top:16px;
        }
        .attach-btn {
          flex:1; display:flex; flex-direction:column; align-items:center; gap:6px;
          background:none; border:none; cursor:pointer;
          font-family:var(--font); font-size:11px; font-weight:700; color:var(--green);
          padding:8px 0; border-radius:12px; transition:background 0.12s;
        }
        .attach-btn:hover { background:#eef2ef; }
        .attach-icon-wrap {
          width:40px; height:40px; border-radius:50%;
          background:var(--sage); display:flex; align-items:center; justify-content:center;
        }

        .nav {
          position:absolute; bottom:0; left:0; right:0; height:72px;
          background:#fff; border-top:1px solid var(--border);
          display:flex; justify-content:space-around; align-items:center;
          padding:0 4px 10px;
        }
        .ni { display:flex; flex-direction:column; align-items:center; gap:3px; padding:5px 8px; cursor:pointer; }
        .nl { font-family:var(--font); font-size:9.5px; font-weight:700; color:#bbb; }
        .nl.on { color:var(--green); font-weight:900; }
      `}</style>

      <div className="phone">
        {/* Status bar */}
        <div className="status">
          <span>9:41</span>
          <div className="status-r">
            <svg width="17" height="12" viewBox="0 0 17 12" fill="none">
              <rect x="0"    y="3" width="3" height="9"  rx="1" fill="#000"/>
              <rect x="4.5"  y="2" width="3" height="10" rx="1" fill="#000"/>
              <rect x="9"    y="0" width="3" height="12" rx="1" fill="#000"/>
              <rect x="13.5" y="0" width="3" height="12" rx="1" fill="#000" opacity="0.3"/>
            </svg>
            <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
              <path d="M8 2.5C10.5 2.5 12.7 3.6 14.2 5.3L15.5 4C13.6 1.9 11 0.5 8 0.5C5 0.5 2.4 1.9 0.5 4L1.8 5.3C3.3 3.6 5.5 2.5 8 2.5Z" fill="#000"/>
              <path d="M8 5.5C9.7 5.5 11.2 6.3 12.2 7.5L13.5 6.2C12.1 4.7 10.2 3.7 8 3.7C5.8 3.7 3.9 4.7 2.5 6.2L3.8 7.5C4.8 6.3 6.3 5.5 8 5.5Z" fill="#000"/>
              <circle cx="8" cy="10.5" r="1.5" fill="#000"/>
            </svg>
            <svg width="25" height="12" viewBox="0 0 25 12" fill="none">
              <rect x="0.5" y="0.5" width="21" height="11" rx="3.5" stroke="#000" strokeOpacity="0.35"/>
              <rect x="2" y="2" width="17" height="8" rx="2" fill="#000"/>
              <path d="M23 4.5V7.5C23.8 7.2 24.5 6.2 24.5 6C24.5 5.8 23.8 4.8 23 4.5Z" fill="#000" opacity="0.4"/>
            </svg>
          </div>
        </div>

        {/* Active screen */}
        {activeTab === "home"    && <HomeScreen />}
        {activeTab === "post"    && <PostComposer onClose={() => setActiveTab("home")} />}
        {activeTab === "ralleys" && <PlaceholderScreen label="Discover Ralleys" tabIcon={<SearchIcon on={true}/>} />}
        {activeTab === "teams"   && <PlaceholderScreen label="Your Teams" tabIcon={<TeamsIcon on={true}/>} />}
        {activeTab === "profile" && <PlaceholderScreen label="Your Profile" tabIcon={<PersonIcon on={true}/>} />}

        {/* Bottom nav */}
        <div className="nav">
          {tabs.map(({ id, label, icon }) => (
            <div key={id} className="ni" onClick={() => setActiveTab(id)}>
              {icon(activeTab === id)}
              {id !== "post" && <span className={`nl ${activeTab === id ? "on" : ""}`}>{label}</span>}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
