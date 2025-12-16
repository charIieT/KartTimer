# KartTimer Support Site

This is the GitHub Pages support site for the KartTimer app.

## Setup Instructions

### If you haven't created a GitHub repository yet:

1. **Create a new repository on GitHub**
   - Go to https://github.com/new
   - Name it: `KartTimer` (or your preferred name)
   - Make it **Private**
   - Click "Create repository"

2. **Push your local code to GitHub** (keep repository private)
   ```bash
   cd /Users/charliet/Desktop/KartTimer
   git remote add origin https://github.com/YOUR_USERNAME/KartTimer.git
   git branch -M main
   git push -u origin main
   ```
   Make sure to set the repository to **Private** in GitHub settings.

### Enable GitHub Pages:

1. Go to your repository on GitHub
2. Click **Settings** (top right)
3. Scroll down to **Pages** section (left sidebar)
4. Under "Source", select:
   - Branch: `main`
   - Folder: `/docs`
5. Click **Save**

GitHub will display your site URL (usually `https://YOUR_USERNAME.github.io/KartTimer`)

### Update your App Store Support URL:

Use the GitHub Pages URL generated above as your Support URL in App Store Connect.

Example: `https://charliet.github.io/KartTimer`

## Customization

Edit `docs/index.html` to:
- Change the email address (currently `support@karttimer.app`)
- Update the GitHub link to your repository
- Modify colors, text, or layout as needed

## Support Email

You'll need to set up an email address for support inquiries. Options:
- Use your personal email
- Create a Gmail account specifically for support
- Use a service like Mailgun or SendGrid for automated responses
