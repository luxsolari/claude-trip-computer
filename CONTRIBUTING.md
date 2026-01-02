# Contributing to Claude Code Session Stats Tracking

Thank you for your interest in contributing! This project follows strict conventions to maintain consistency and quality.

## Development Conventions (REQUIRED)

This project **strictly enforces** the following conventions for all contributions:

### 1. Semantic Versioning (SemVer)

**REQUIRED:** All version numbers MUST follow [Semantic Versioning 2.0.0](https://semver.org/)

**Format:** `MAJOR.MINOR.PATCH`

**Rules:**
- **MAJOR** version: Increment for incompatible API changes or breaking changes
  - Example: `1.0.0` → `2.0.0` (breaking change to script interface)
- **MINOR** version: Increment for new backward-compatible functionality
  - Example: `0.5.1` → `0.6.0` (added prompt analysis feature)
- **PATCH** version: Increment for backward-compatible bug fixes
  - Example: `0.5.0` → `0.5.1` (fixed locale warning)

**Files to Update:**
1. `VERSION` - Single source of truth
2. `CHANGELOG.md` - Document the version
3. `CLAUDE.md` - Update version references
4. `README.md` - Update version badge
5. `install-claude-stats.sh` - Embedded script versions
6. `~/.claude/hooks/*.sh` - Script header versions

### 2. Conventional Commits

**REQUIRED:** All commit messages MUST follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/)

**Format:**
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Allowed Types:**
- `feat`: New feature (correlates with MINOR in SemVer)
- `fix`: Bug fix (correlates with PATCH in SemVer)
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI configuration
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

**Scopes (optional but recommended):**
- `trip-computer`: Changes to show-session-stats.sh
- `status-line`: Changes to brief-stats.sh
- `installer`: Changes to install-claude-stats.sh
- `docs`: Documentation changes
- `pricing`: Pricing/cost calculation changes

**Examples:**

```bash
# Feature addition (MINOR version bump)
git commit -m "feat(trip-computer): add prompt quality analysis with 4 pattern detectors

Implements automatic detection of inefficient prompting patterns.
Adds vague questions, large pastes, repeated questions, and missing
constraints detectors with estimated savings calculations."

# Bug fix (PATCH version bump)
git commit -m "fix(status-line): correct token deduplication for multi-model sessions

Fixed issue where tokens were double-counted when multiple models
were used in the same session."

# Documentation update (no version bump)
git commit -m "docs(readme): update installation instructions for Windows

Added clarity around WSL vs Git Bash requirements."

# Breaking change (MAJOR version bump)
git commit -m "feat(installer): change billing config format to JSON

BREAKING CHANGE: Config file format changed from bash source to JSON.
Users must re-run installer to migrate configuration."
```

**Breaking Changes:**
- MUST include `BREAKING CHANGE:` in footer or `!` after type/scope
- MUST bump MAJOR version
- Example: `feat!: remove support for bash 3.x`

### 3. Keep a Changelog

**REQUIRED:** All changes MUST be documented in [CHANGELOG.md](CHANGELOG.md) following [Keep a Changelog 1.1.0](https://keepachangelog.com/)

**Format:**
```markdown
## [Version] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```

**Rules:**
1. **Unreleased section** at the top for upcoming changes
2. **Version sections** in reverse chronological order
3. **Dates** in ISO 8601 format (YYYY-MM-DD)
4. **Grouping** by change type (Added, Changed, Fixed, etc.)
5. **Descriptions** focus on user impact, not implementation details
6. **Links** to version diffs at the bottom

**Workflow:**
1. Add changes to `[Unreleased]` section as you work
2. When ready to release:
   - Move `[Unreleased]` changes to new version section
   - Add version number and date
   - Update version links at bottom

## Workflow for Making Changes

### 1. Branch Naming

Use descriptive branch names following this pattern:
- `feature/v0.X-description` - New features
- `fix/issue-description` - Bug fixes
- `docs/topic` - Documentation updates
- `refactor/component` - Code refactoring

### 2. Development Process

```bash
# 1. Create feature branch
git checkout -b feature/v0.7-cache-optimization

# 2. Make changes
# ... edit files ...

# 3. Update VERSION file
echo "0.7.0" > VERSION

# 4. Update CHANGELOG.md
# Add entry under [Unreleased] or create new version section

# 5. Update documentation
# Update CLAUDE.md, README.md as needed

# 6. Update installer if needed
# Embed new script versions in install-claude-stats.sh

# 7. Test changes
./install-claude-stats.sh
~/.claude/hooks/show-session-stats.sh

# 8. Commit with conventional commit message
git add -A
git commit -m "feat(trip-computer): add cache optimization recommendations

Analyzes cache hit patterns and suggests optimal session length
based on cache efficiency trends over time.

- Tracks cache performance over session lifetime
- Recommends /clear when cache efficiency drops below 40%
- Estimates savings from optimal session reset timing

Technical:
- Added cache trend analysis (20 lines)
- Updated recommendation prioritization
- Added unit tests for cache calculations"

# 9. Push and create PR
git push -u origin feature/v0.7-cache-optimization
```

### 3. Pre-Commit Checklist

Before committing, verify:

- [ ] Version number updated in `VERSION` file (if applicable)
- [ ] CHANGELOG.md updated with changes
- [ ] All version references consistent across files
- [ ] CLAUDE.md documentation updated (if applicable)
- [ ] README.md updated (if user-facing changes)
- [ ] Installer script updated (if script changes)
- [ ] Commit message follows Conventional Commits format
- [ ] Code tested (installer runs, trip computer works)
- [ ] No syntax errors (`bash -n script.sh`)
- [ ] Cross-platform compatibility maintained

### 4. Pull Request Guidelines

**PR Title:** Must follow Conventional Commits format
```
feat(trip-computer): add cache optimization recommendations
```

**PR Description Template:**
```markdown
## Summary
Brief description of changes

## Type of Change
- [ ] feat: New feature (MINOR version bump)
- [ ] fix: Bug fix (PATCH version bump)
- [ ] docs: Documentation only
- [ ] refactor: Code refactoring
- [ ] BREAKING CHANGE (MAJOR version bump)

## Changes Made
- Bullet point list of specific changes
- Focus on what changed and why

## Testing
- How was this tested?
- Which platforms were tested?

## Documentation
- [ ] CHANGELOG.md updated
- [ ] VERSION file updated (if applicable)
- [ ] CLAUDE.md updated (if applicable)
- [ ] README.md updated (if applicable)

## Checklist
- [ ] Follows Conventional Commits
- [ ] Follows Semantic Versioning
- [ ] All version references consistent
- [ ] Tests pass
- [ ] Documentation complete
```

## Version Release Process

### Creating a New Release

```bash
# 1. Ensure you're on master/main branch
git checkout master
git pull

# 2. Create release branch
git checkout -b release/v0.7.0

# 3. Update VERSION file
echo "0.7.0" > VERSION

# 4. Update CHANGELOG.md
# Move [Unreleased] changes to [0.7.0] with current date

# 5. Update all documentation
# Ensure all version references are consistent

# 6. Commit release
git commit -m "chore(release): bump version to 0.7.0

Updated VERSION, CHANGELOG.md, and all documentation
for v0.7.0 release."

# 7. Merge to master
git checkout master
git merge release/v0.7.0

# 8. Create git tag
git tag -a v0.7.0 -m "Release v0.7.0

Cache optimization recommendations
- Analyzes cache hit patterns
- Suggests optimal session length
- Estimates savings from reset timing"

# 9. Push with tags
git push origin master --tags

# 10. Clean up release branch
git branch -d release/v0.7.0
```

## Code Style Guidelines

### Bash Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Use `set -u` if appropriate (all vars defined)
- Export `LC_NUMERIC=C` for number formatting
- Use `[[ ]]` instead of `[ ]` for conditionals
- Quote all variable expansions: `"$VAR"`
- Use `local` for function variables
- Add comments for complex logic
- Keep functions under 50 lines when possible

### jq Queries

- Use multiline format for readability
- Add comments explaining complex filters
- Test with various input scenarios
- Handle null/empty cases with `// 0` or `// empty`

### Documentation

- Use markdown format
- Include code examples
- Document all parameters and return values
- Update CLAUDE.md for technical details
- Update README.md for user-facing changes

## Questions or Issues?

- Check [CLAUDE.md](CLAUDE.md) for technical documentation
- Review [CHANGELOG.md](CHANGELOG.md) for version history
- See existing commits for examples of good commit messages

## License

By contributing, you agree that your contributions will be licensed under the same license as this project.
