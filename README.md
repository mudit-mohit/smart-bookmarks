# Smart Bookmark Manager

A full-stack bookmark management application built with Next.js, Supabase, and Tailwind CSS. Users can sign in with Google OAuth, save bookmarks with real-time synchronization across multiple tabs, and manage their personal bookmark collection.

🔗 **Live Demo**: [https://smart-bookmarks-seven.vercel.app/](https://smart-bookmarks-seven.vercel.app/)
📦 **GitHub Repository**: [https://github.com/mudit-mohit/smart-bookmarks](https://github.com/mudit-mohit/smart-bookmarks)

---

## Features

✅ **Google OAuth Authentication** - Secure sign-in/sign-up using Google (no email/password)  
✅ **Add Bookmarks** - Save URLs with custom titles  
✅ **Private Bookmarks** - Each user's bookmarks are completely isolated using Row Level Security  
✅ **Real-time Updates** - Changes sync instantly across all browser tabs without page refresh  
✅ **Delete Bookmarks** - Remove bookmarks with a single click  
✅ **Responsive Design** - Clean UI that works on desktop and mobile  

---

## Tech Stack

- **Frontend**: Next.js 14 (App Router), React 18, TypeScript
- **Backend**: Supabase (PostgreSQL database, Authentication, Real-time subscriptions)
- **Styling**: Tailwind CSS
- **Deployment**: Vercel
- **Authentication**: Google OAuth 2.0 via Supabase Auth

---

## How It Works

### Authentication Flow
1. User clicks "Sign in with Google" or "Sign up with Google"
2. Redirects to Google OAuth consent screen
3. User authorizes the application
4. Google redirects back with authorization code
5. Supabase exchanges code for session token
6. User is authenticated and can access their bookmarks

### Real-time Synchronization
The app uses Supabase's real-time subscriptions to achieve instant updates:

1. When a user adds/deletes a bookmark, the change is saved to PostgreSQL
2. Supabase broadcasts the change via WebSocket to all connected clients
3. All browser tabs listening to the same user's bookmarks receive the update
4. React state updates automatically, reflecting changes in the UI

This enables the "open two tabs" feature where adding a bookmark in one tab makes it appear instantly in another.

### Data Privacy
Row Level Security (RLS) policies ensure complete data isolation:
- Users can only SELECT their own bookmarks (`user_id = auth.uid()`)
- Users can only INSERT bookmarks with their own user_id
- Users can only DELETE their own bookmarks

This makes it impossible for User A to access User B's bookmarks, even through direct API calls.

---

## Problems Encountered & Solutions

### Problem 1: Environment Variables Not Loading
**Issue**: Initially got error "Invalid supabaseUrl: Must be a valid HTTP or HTTPS URL"

**Root Cause**: The `.env.local` file was not created, so environment variables were undefined.

**Solution**: 
- Added better error handling in `lib/supabase.ts` to check if variables exist
- Improved error messages to guide users

### Problem 2: OAuth Redirect Loop
**Issue**: After Google OAuth, users were redirected but not authenticated.

**Root Cause**: Missing OAuth callback route handler.

**Solution**: 
- Created `/app/api/auth/callback/route.ts` to handle the OAuth callback
- Used `exchangeCodeForSession()` to convert authorization code to session
- Properly configured redirect URI in both Google Cloud Console and Supabase

### Problem 3: Real-time Not Working Initially
**Issue**: Bookmarks weren't syncing across tabs in real-time.

**Root Cause**: Forgot to enable real-time on the bookmarks table.

**Solution**: 
- Added `alter publication supabase_realtime add table bookmarks;` to SQL schema
- Ensured proper subscription cleanup in useEffect to prevent memory leaks
- Filtered real-time events by `user_id` to only receive relevant updates

### Problem 4: Input Text Not Visible
**Issue**: Text in the Title and URL input fields appeared white on white background.

**Root Cause**: Missing text color classes in Tailwind.

**Solution**: 
- Added `text-gray-900` class for input text
- Added `placeholder-gray-400` for placeholder text
- Ensured good contrast for accessibility

### Problem 5: RLS Policies Not Applied
**Issue**: During testing, could see other users' bookmarks briefly.

**Root Cause**: RLS was enabled but policies weren't created yet.

**Solution**: 
- Created comprehensive RLS policies for SELECT, INSERT, and DELETE
- Tested with multiple Google accounts to verify isolation
- Added indexes for performance on `user_id` column

### Problem 6: Vercel Deployment Configuration
**Issue**: First deployment failed due to build errors.

**Root Cause**: Environment variables not set in Vercel dashboard.

**Solution**: 
- Added environment variables in Vercel project settings
- Created `vercel.json` with proper configuration
- Updated Google OAuth to include production URL in authorized origins

---

## Setup Instructions

### Prerequisites
- Node.js 18+ installed
- Google account
- Supabase account
- Vercel account

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/smart-bookmarks.git
cd smart-bookmarks
npm install
```

### 2. Set Up Supabase

1. Go to [supabase.com](https://supabase.com) and create a new project
2. In SQL Editor, run the following schema:

```sql
-- Create bookmarks table
create table bookmarks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  title text not null,
  url text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security
alter table bookmarks enable row level security;

-- Create policies
create policy "Users can view their own bookmarks"
  on bookmarks for select
  using (auth.uid() = user_id);

create policy "Users can insert their own bookmarks"
  on bookmarks for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own bookmarks"
  on bookmarks for delete
  using (auth.uid() = user_id);

-- Enable real-time
alter publication supabase_realtime add table bookmarks;

-- Add indexes for performance
create index bookmarks_user_id_idx on bookmarks(user_id);
create index bookmarks_created_at_idx on bookmarks(created_at desc);
```

3. Go to Authentication → Providers → Enable Google
4. Note the callback URL (you'll need this for Google OAuth)

### 3. Configure Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Go to Credentials → Create OAuth 2.0 Client ID
5. Add authorized redirect URI from Supabase
6. Copy Client ID and Client Secret to Supabase Google provider settings

### 4. Environment Variables

Create `.env.local` in the project root:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

Get these from Supabase Dashboard → Project Settings → API

### 5. Run Locally

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

### 6. Deploy to Vercel

```bash
npm install -g vercel
vercel login
vercel
```

Or connect your GitHub repo to Vercel dashboard.

**Important**: Add environment variables in Vercel project settings!

### 7. Update Google OAuth

After deployment, add your Vercel production URL to Google Cloud Console authorized origins.

---

## Testing the Real-time Feature

1. Open the app in two separate browser tabs
2. Sign in with the same Google account in both
3. In Tab 1: Add a bookmark (e.g., "GitHub" - "https://github.com")
4. Watch Tab 2: The bookmark appears instantly without refresh!
5. In Tab 2: Delete the bookmark
6. Watch Tab 1: It disappears immediately!

---

## Project Structure

```
smart-bookmarks/
├── app/
│   ├── api/
│   │   └── auth/
│   │       └── callback/
│   │           └── route.ts       # OAuth callback handler
│   ├── globals.css                # Tailwind styles
│   ├── layout.tsx                 # Root layout
│   └── page.tsx                   # Main app component
├── lib/
│   └── supabase.ts                # Supabase client configuration
├── public/                        # Static assets
├── .env.local                     # Environment variables (not in git)
├── .env.local.example             # Environment template
├── .gitignore                     # Git ignore rules
├── next.config.js                 # Next.js configuration
├── package.json                   # Dependencies
├── postcss.config.js              # PostCSS configuration
├── tailwind.config.js             # Tailwind configuration
├── tsconfig.json                  # TypeScript configuration
├── vercel.json                    # Vercel deployment config
└── README.md                      # This file
```

---

## Database Schema

```sql
Table: bookmarks
├── id (uuid, primary key)
├── user_id (uuid, foreign key → auth.users)
├── title (text, not null)
├── url (text, not null)
└── created_at (timestamp with time zone)

Indexes:
├── bookmarks_user_id_idx (user_id)
└── bookmarks_created_at_idx (created_at DESC)

RLS Policies:
├── Users can view their own bookmarks
├── Users can insert their own bookmarks
└── Users can delete their own bookmarks
```

---

## Security Features

- **Row Level Security (RLS)**: Database-level isolation ensures users can only access their own data
- **OAuth 2.0**: Secure authentication without storing passwords
- **Environment Variables**: Sensitive keys stored securely, never committed to git
- **Type Safety**: Full TypeScript implementation prevents runtime errors
- **HTTPS**: Enforced in production via Vercel
- **CORS**: Properly configured for Supabase authentication

---

## Performance Optimizations

- **Real-time Subscriptions**: WebSocket connections for instant updates instead of polling
- **Database Indexes**: Fast queries on `user_id` and `created_at` columns
- **Optimistic UI**: Form clears immediately after submission for better UX
- **React State Management**: Efficient state updates prevent unnecessary re-renders
- **Lazy Loading**: Components load on-demand

---

## Future Enhancements

- [ ] Add bookmark categories/tags
- [ ] Search and filter functionality
- [ ] Bookmark import/export (JSON, CSV)
- [ ] Browser extension for quick bookmarking
- [ ] Bookmark sharing with other users
- [ ] Rich link previews with thumbnails
- [ ] Bulk operations (delete multiple, move to folder)
- [ ] Dark mode toggle

---

## Known Limitations

- Google OAuth only (no email/password option by design)
- No offline support (requires internet connection)
- Real-time requires WebSocket support (works on modern browsers)
- Maximum URL length: 2048 characters (browser limitation)

---

## Browser Support

- Chrome/Edge: ✅ Full support
- Firefox: ✅ Full support  
- Safari: ✅ Full support
- Mobile browsers: ✅ Responsive design

---

## License

MIT License - Free to use and modify

---

## Acknowledgments

- **Next.js** - React framework
- **Supabase** - Backend as a service
- **Vercel** - Deployment platform
- **Tailwind CSS** - Utility-first CSS framework
- **Google** - OAuth provider

---

## Contact

For questions about this project, please open an issue on GitHub.

---

**Built with ❤️**
