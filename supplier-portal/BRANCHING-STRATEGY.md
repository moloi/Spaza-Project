# Branching & Deployment Strategy

## Branch Flow

```
feature/* ──► develop ──► release ──► main
   (local)       (QA)      (Staging)   (Production)
```

## Branches

| Branch      | Purpose                    | Deploys To    | Trigger      |
|-------------|----------------------------|---------------|--------------|
| `feature/*` | Local development          | —             | —            |
| `develop`   | Integration & QA testing   | QA Server     | Push/Merge   |
| `release`   | Pre-production validation  | Staging Server| Push/Merge   |
| `main`      | Production-ready code      | Production    | Push/Merge   |

## Rules

1. **No direct pushes to `main`** — code must go through `develop` → `release` → `main`
2. **No direct pushes to `release`** — only merges from `develop` via Pull Request
3. **Feature branches** are created from `develop` and merged back into `develop`
4. All merges to `release` and `main` require Pull Request approval

## Developer Workflow

### 1. Start a new feature
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature-name
```

### 2. Work on your feature locally
```bash
# Make changes, commit often
git add .
git commit -m "feat: description of change"
```

### 3. Push feature and create PR to develop
```bash
git push -u origin feature/my-feature-name
# Create Pull Request: feature/my-feature-name → develop
```

### 4. After PR approved & merged → QA deployment triggers automatically

### 5. QA approved → Create PR from develop to release
```bash
# Create Pull Request: develop → release
```

### 6. Release validated → Create PR from release to main
```bash
# Create Pull Request: release → main
# Production deployment triggers automatically
```

## GitHub Secrets Required

### QA Environment
- `QA_HOST` — QA server IP/hostname
- `QA_USERNAME` — SSH username for QA server
- `QA_SSH_KEY` — SSH private key for QA server

### Release/Staging Environment
- `RELEASE_HOST` — Staging server IP/hostname
- `RELEASE_USERNAME` — SSH username for Staging server
- `RELEASE_SSH_KEY` — SSH private key for Staging server

### Production Environment
- `PROD_HOST` — Production server IP/hostname
- `PROD_USERNAME` — SSH username for Production server
- `PROD_SSH_KEY` — SSH private key for Production server

## Branch Protection Rules (Set in GitHub)

Go to: Repository → Settings → Branches → Add rule

### For `main`:
- ✅ Require pull request before merging
- ✅ Require approvals (minimum 1)
- ✅ Require status checks to pass (PR Validation)
- ✅ Restrict direct pushes

### For `release`:
- ✅ Require pull request before merging
- ✅ Require status checks to pass (PR Validation)
- ✅ Restrict direct pushes

### For `develop`:
- ✅ Require pull request before merging
- ✅ Require status checks to pass (PR Validation)
