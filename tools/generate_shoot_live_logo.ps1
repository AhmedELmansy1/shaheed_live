$svgContent = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <!-- Background Gradient -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0B0F19" />
      <stop offset="50%" stop-color="#111827" />
      <stop offset="100%" stop-color="#070A10" />
    </linearGradient>

    <!-- Outer Border Gradient -->
    <linearGradient id="borderGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF3B30" />
      <stop offset="50%" stop-color="#FF8A00" />
      <stop offset="100%" stop-color="#FFB800" />
    </linearGradient>

    <!-- Speed Comet Flame Gradient -->
    <linearGradient id="flameGrad1" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#FF3B30" stop-opacity="0" />
      <stop offset="40%" stop-color="#FF3B30" stop-opacity="0.85" />
      <stop offset="100%" stop-color="#FF9500" stop-opacity="1" />
    </linearGradient>

    <linearGradient id="flameGrad2" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#FF9500" stop-opacity="0" />
      <stop offset="50%" stop-color="#FFB800" stop-opacity="0.9" />
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="1" />
    </linearGradient>

    <!-- Football Sphere Shading Gradient -->
    <radialGradient id="ballShading" cx="36%" cy="32%" r="68%">
      <stop offset="0%" stop-color="#FFFFFF" />
      <stop offset="55%" stop-color="#F1F5F9" />
      <stop offset="82%" stop-color="#CBD5E1" />
      <stop offset="100%" stop-color="#64748B" />
    </radialGradient>

    <!-- Glow Filter -->
    <filter id="liveGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="8" result="blur" />
      <feMerge>
        <feMergeNode in="blur" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
  </defs>

  <!-- ================= 1. SQUIRCLE BACKGROUND ================= -->
  <!-- Outer Drop Shadow -->
  <rect x="16" y="24" width="480" height="480" rx="116" fill="#000000" opacity="0.5" />

  <!-- App Icon Base -->
  <rect x="16" y="16" width="480" height="480" rx="116" fill="url(#bgGrad)" />

  <!-- Metallic / Neon Edge Rim -->
  <rect x="16" y="16" width="480" height="480" rx="116" fill="none" stroke="url(#borderGrad)" stroke-width="7" />

  <!-- Inner Ambient Glow / Field Ring -->
  <circle cx="260" cy="245" r="175" fill="none" stroke="#FFFFFF" stroke-opacity="0.05" stroke-width="2" />
  <circle cx="260" cy="245" r="145" fill="none" stroke="url(#borderGrad)" stroke-opacity="0.25" stroke-width="3" stroke-dasharray="14 10" />

  <!-- ================= 2. SPEED COMET TRAILS ("SHOOT / شوت") ================= -->
  <!-- Outer Speed Flame Trail -->
  <path d="M 80 410 C 130 395 170 350 205 315 C 220 300 235 285 250 270 C 225 295 195 340 145 385 C 120 405 95 412 80 410 Z"
        fill="url(#flameGrad1)" filter="url(#liveGlow)" />

  <!-- Main Blazing Rocket Trail -->
  <path d="M 95 435 C 150 420 200 365 240 315 C 260 290 280 265 290 245 C 265 275 230 335 175 395 C 140 430 110 438 95 435 Z"
        fill="url(#flameGrad1)" />

  <!-- Core White-Hot Acceleration Streak -->
  <path d="M 140 415 C 185 390 230 340 265 285 C 280 260 290 245 295 235 C 280 255 250 310 205 365 C 175 400 150 415 140 415 Z"
        fill="url(#flameGrad2)" />

  <!-- Dynamic Speed Streaks Behind Ball -->
  <line x1="90" y1="360" x2="160" y2="290" stroke="#FF3B30" stroke-width="4" stroke-linecap="round" opacity="0.7" />
  <line x1="120" y1="390" x2="195" y2="315" stroke="#FF9500" stroke-width="5" stroke-linecap="round" opacity="0.85" />
  <line x1="150" y1="420" x2="225" y2="345" stroke="#FFB800" stroke-width="4" stroke-linecap="round" opacity="0.7" />

  <!-- ================= 3. THE 3D FOOTBALL ================= -->
  <!-- Ball Drop Shadow -->
  <ellipse cx="260" cy="340" rx="80" ry="16" fill="#000000" opacity="0.6" filter="url(#liveGlow)" />

  <g id="football">
    <clipPath id="ballClip">
      <circle cx="270" cy="235" r="88" />
    </clipPath>

    <!-- 3D Shaded Leather Sphere -->
    <circle cx="270" cy="235" r="88" fill="url(#ballShading)" />

    <!-- Pentagon Panels clipped inside ball -->
    <g clip-path="url(#ballClip)">
      <!-- Central Pentagon (Slightly angled in flight) -->
      <!-- Center at (270, 235) -->
      <polygon points="270,207 296,226 286,256 254,256 244,226" fill="#0F172A" stroke="#1E293B" stroke-width="3" />

      <!-- Outer Edge Pentagons -->
      <!-- Top -->
      <polygon points="270,147 252,160 258,180 282,180 288,160" fill="#0F172A" stroke="#1E293B" stroke-width="3" />
      <!-- Top-Right -->
      <polygon points="358,217 340,201 326,213 334,233 356,231" fill="#0F172A" stroke="#1E293B" stroke-width="3" />
      <!-- Bottom-Right -->
      <polygon points="338,299 344,277 326,267 310,283 318,303" fill="#0F172A" stroke="#1E293B" stroke-width="3" />
      <!-- Bottom-Left -->
      <polygon points="202,299 194,277 214,267 230,283 222,303" fill="#0F172A" stroke="#1E293B" stroke-width="3" />
      <!-- Top-Left -->
      <polygon points="182,217 200,201 214,213 206,233 184,231" fill="#0F172A" stroke="#1E293B" stroke-width="3" />

      <!-- Seam Lines connecting Center to Edge Pentagons -->
      <line x1="270" y1="207" x2="270" y2="180" stroke="#1E293B" stroke-width="3.5" stroke-linecap="round" />
      <line x1="296" y1="226" x2="326" y2="213" stroke="#1E293B" stroke-width="3.5" stroke-linecap="round" />
      <line x1="286" y1="256" x2="310" y2="283" stroke="#1E293B" stroke-width="3.5" stroke-linecap="round" />
      <line x1="254" y1="256" x2="230" y2="283" stroke="#1E293B" stroke-width="3.5" stroke-linecap="round" />
      <line x1="244" y1="226" x2="214" y2="213" stroke="#1E293B" stroke-width="3.5" stroke-linecap="round" />

      <!-- 3D Specular Highlight Gloss -->
      <ellipse cx="240" cy="195" rx="36" ry="18" transform="rotate(-30 240 195)"
               fill="#FFFFFF" opacity="0.5" />

      <!-- Bottom Sphere Shadow -->
      <path d="M 182 235 A 88 88 0 0 0 358 235 Z" fill="#0A0F1D" opacity="0.25" />
    </g>

    <!-- Sphere Edge Ring -->
    <circle cx="270" cy="235" r="88" fill="none" stroke="#FFFFFF" stroke-opacity="0.4" stroke-width="2" />
  </g>

  <!-- ================= 4. "LIVE" PULSE ORBIT & BEACON ================= -->
  <!-- Live Pulse Orbit Ring -->
  <path d="M 190 190 C 220 150 280 140 330 160 C 375 178 400 220 395 265 C 390 310 355 350 310 365 C 265 380 215 365 185 335"
        fill="none" stroke="#FF3B30" stroke-width="4.5" stroke-linecap="round" stroke-dasharray="160 30" filter="url(#liveGlow)" />

  <!-- Live Pulse Beacon / Indicator at Top-Right Orbit -->
  <circle cx="365" cy="190" r="16" fill="#FF3B30" opacity="0.3" filter="url(#liveGlow)" />
  <circle cx="365" cy="190" r="9" fill="#FF3B30" />
  <circle cx="365" cy="190" r="4.5" fill="#FFFFFF" />

  <!-- Live Text Pill at Bottom Center -->
  <g transform="translate(186, 420)">
    <rect width="140" height="36" rx="18" fill="#FF3B30" />
    <circle cx="26" cy="18" r="5" fill="#FFFFFF" />
    <text x="76" y="24" font-family="'Segoe UI', Roboto, Cairo, sans-serif" font-size="16" font-weight="900" fill="#FFFFFF" text-anchor="middle" letter-spacing="2">LIVE</text>
  </g>
</svg>
'@

$svgPath = "D:\My_Project\shoot_live\assets\branding\modarraj_logo.svg"
[System.IO.File]::WriteAllText($svgPath, $svgContent, [System.Text.Encoding]::UTF8)
Write-Host "Shoot Live SVG written to $svgPath"

