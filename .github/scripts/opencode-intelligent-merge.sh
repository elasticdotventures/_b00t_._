#!/bin/bash
# Intelligent merge script using opencode for conflict resolution

set -e

echo "🤖 Starting intelligent merge with opencode..."

# Try standard merge first
if git merge dotfiles/main --allow-unrelated-histories -X theirs -m "Merge dotfiles updates" 2>/dev/null; then
    echo "✅ Clean merge successful"
    exit 0
fi

echo "⚠️ Merge conflicts detected, invoking opencode..."

# Get list of conflicted files
CONFLICTS=$(git diff --name-only --diff-filter=U)

for file in $CONFLICTS; do
    echo "🔍 Resolving conflicts in: $file"
    
    # Create prompt for opencode
    cat > /tmp/merge-prompt.txt <<EOF
You are a git merge conflict resolver. Intelligently merge these two versions of $file:

=== CURRENT VERSION (HEAD) ===
$(git show HEAD:$file 2>/dev/null || echo "FILE NOT IN HEAD")

=== INCOMING VERSION (dotfiles/main) ===  
$(git show dotfiles/main:$file 2>/dev/null || echo "FILE NOT IN DOTFILES")

=== CONFLICTED VERSION ===
$(cat $file)

INSTRUCTIONS:
- Preserve _b00t_ specific customizations
- Accept dotfiles improvements and updates
- Remove conflict markers (<<<<<<< ======= >>>>>>>)
- Output only the final merged content
- Maintain file formatting and structure
EOF

    # Use opencode to resolve (fallback to manual if not available)
    if command -v opencode >/dev/null 2>&1; then
        opencode "$(cat /tmp/merge-prompt.txt)" > /tmp/resolved-$file
        cp /tmp/resolved-$file $file
        git add $file
        echo "✅ Resolved $file with opencode"
    else
        echo "⚠️ opencode not available, using theirs strategy for $file"
        git checkout --theirs $file
        git add $file
    fi
done

# Complete the merge
git commit -m "Intelligent merge of dotfiles updates

🤖 Resolved conflicts using opencode
📁 Files merged: $(echo $CONFLICTS | tr '\n' ' ')
"

echo "🎉 Intelligent merge completed successfully"