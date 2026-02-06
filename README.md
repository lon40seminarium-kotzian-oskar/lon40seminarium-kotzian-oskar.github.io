# Elektronika (Django)

Minimal instructions to push this project to GitHub and deploy on Render.com.

1. Create a Git repository and push to GitHub:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin <your-github-repo-url>
git push -u origin main
```

2. On Render.com:
- Create a new Web Service and connect your GitHub repo, or import using `render.yaml`.
- Set the build command and start command are already in `render.yaml`:
  - `buildCommand`: `pip install -r requirements.txt && python manage.py collectstatic --noinput`
  - `startCommand`: `gunicorn elektronika.wsgi:application`
- Add any required environment variables (e.g., `SECRET_KEY`, `DEBUG=False`).

3. Local notes:
- Install dependencies: `pip install -r requirements.txt`
- Run locally: `python manage.py runserver`
