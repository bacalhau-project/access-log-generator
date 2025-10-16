# Setting Up GHCR_TOKEN for Docker Image Releases

To enable GitHub Actions to build and push Docker images to GitHub Container Registry (GHCR), you need to create and configure a personal access token.

## Steps

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
