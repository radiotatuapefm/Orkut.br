/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: { 
    unoptimized: true,
    domains: ['images.pexels.com', 'woyyikaztjrhqzgvbhmn.supabase.co']
  },
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://vercel.live",
              "style-src 'self' 'unsafe-inline'",
              "img-src 'self' data: https: blob:",
              "font-src 'self' data:",
              "connect-src 'self' https://woyyikaztjrhqzgvbhmn.supabase.co wss://woyyikaztjrhqzgvbhmn.supabase.co https://vercel.live",
              "media-src 'self' blob:",
              "worker-src 'self' blob:",
              "frame-src 'self'",
              "object-src 'none'",
              "base-uri 'self'"
            ].join('; ')
          }
        ]
      }
    ];
  },
};

module.exports = nextConfig;
