# Setting Up GitHub Actions for Docker Image Releases

GitHub Actions automatically provides `secrets.GITHUB_TOKEN` which has the necessary permissions to build and push Docker images to GitHub Container Registry (GHCR). No additional setup is required!

The workflow uses `secrets.GITHUB_TOKEN` by default, which:
- ✅ Has `write:packages` scope for GHCR
- ✅ Is automatically created for each workflow run
- ✅ Has appropriate permissions for your repository
- ✅ Requires no manual configuration

## How It Works

When a tag is pushed (e.g., `git push origin v2.8.0`), GitHub Actions:
1. Automatically logs in to GHCR using `secrets.GITHUB_TOKEN`
2. Builds multi-arch Docker images (amd64, arm64)
3. Pushes to ghcr.io with tags: `v2.8.0`, `2.8`, `2`, `latest`
4. Creates build attestations

## Alternative: Using a Personal Access Token (Optional)

If you need additional permissions or want to use a custom token, you can still set up a personal access token:

### 1. Create Personal Access Token

1. Go to https://github.com/settings/tokens/new
2. Give it a name like "GHCR Release Token"
3. Set expiration (recommend 90 days or Custom for longer)
4. Select the following scopes:
   - ✅ `write:packages` - Push packages to GHCR
   - ✅ `read:packages` - Read packages (optional but recommended)
   - ✅ `repo` - (optional) For full access if needed

5. Click "Generate token" and copy the token

### 2. Add to Repository Secrets

1. Go to https://github.com/bacalhau-project/access-log-generator/settings/secrets/actions
2. Click "New repository secret"
3. Name: `GHCR_TOKEN`
4. Value: Paste the token from step 1
5. Click "Add secret"

### 3. Update Workflow (if using custom token)

Update `.github/workflows/build-and-push.yml` to use `secrets.GHCR_TOKEN` instead of `secrets.GITHUB_TOKEN`

### 3. Verify

The GitHub Actions workflow will now be able to:
- Build multi-arch Docker images (amd64, arm64)
- Push to ghcr.io with tags: `v2.3.0`, `2.3`, `2`, `latest`
- Create build attestations

## Troubleshooting

If you still see `permission_denied: write_package`:

1. **Token expired?** Create a new one and update the secret
2. **Wrong scope?** Make sure `write:packages` is selected
3. **Repository secret?** Verify it's added at the repository level, not organization level
4. **Token format?** Should start with `ghp_` for personal access tokens

## Token Security

- ⚠️ **Never commit tokens to git**
- ⚠️ **Regenerate if accidentally exposed**
- ✅ Always use GitHub Secrets for sensitive data
- ✅ Rotate tokens periodically (every 90 days recommended)

## More Information

- [GitHub Container Registry docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Creating personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
