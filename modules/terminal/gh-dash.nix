let
  parent = "terminal";
  module = "gh-dash";

  # Shared shell function to extract org/repo from any GitHub remote URL.
  # Handles: https://github.com/..., git@github.com:..., git@<ssh-alias>:...
  # Resolves SSH aliases via ~/.ssh/config to check if they point to github.com.
  # Cannot use `ssh -G` because nix openssh doesn't support macOS UseKeychain.
  extractRepoFn = ''
    extract_repo() {
        local url="$1"
        # Direct github.com URLs (HTTPS or SSH)
        if [[ "$url" == *github.com* ]]; then
            echo "$url" | sed -E 's/.*github\.com[:\/]([^\/]+\/[^\.]+)(\.git)?/\1/'
            return
        fi
        # SSH alias: git@<alias>:<org>/<repo>.git
        if [[ "$url" =~ ^git@([^:]+):(.+)$ ]]; then
            local host="''${BASH_REMATCH[1]}"
            local path="''${BASH_REMATCH[2]}"
            # Parse ~/.ssh/config to resolve the alias hostname
            local real_host=""
            local in_block=false
            while IFS= read -r line; do
                if [[ "$line" =~ ^[Hh]ost[[:space:]]+(.+)$ ]]; then
                    if [[ "''${BASH_REMATCH[1]}" == "$host" ]]; then
                        in_block=true
                    else
                        in_block=false
                    fi
                elif $in_block && [[ "$line" =~ ^[[:space:]]+[Hh]ost[Nn]ame[[:space:]]+(.+)$ ]]; then
                    real_host="''${BASH_REMATCH[1]}"
                    break
                fi
            done < ~/.ssh/config
            if [[ "$real_host" == "github.com" ]]; then
                echo "$path" | sed -E 's/(\.git)?$//'
                return
            fi
        fi
    }
  '';
in
{
  flake.modules.homeManager.${module} =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.modules.${parent}.${module};

      # Helper: relays an issue from one repo to another, auto-detecting accounts
      # Called by the Shift+C keybinding inside gh-dash
      gh-relay-issue = pkgs.writeShellApplication {
        name = "gh-relay-issue";
        runtimeInputs = with pkgs; [ git gh gnused fzf ];
        text = ''
          ${extractRepoFn}

          issue_number="$1"
          source_repo="$2"

          # Find account with access to source repo
          source_token=""
          if [[ -n "''${GH_TOKEN:-}" ]]; then
              source_token="$GH_TOKEN"
          else
              for account in $(gh auth status 2>&1 | grep "Logged in to" | sed -E 's/.*account ([^ ]+) .*/\1/'); do
                  token=$(gh auth token --user "$account" 2>/dev/null) || continue
                  if GH_TOKEN="$token" gh api "repos/$source_repo" --jq '.full_name' >/dev/null 2>&1; then
                      source_token="$token"
                      break
                  fi
              done
          fi

          if [[ -z "$source_token" ]]; then
              echo "No account has access to $source_repo!"
              sleep 2
              exit 1
          fi

          # Build list of GitHub remotes (excluding the source repo)
          remotes=""
          while IFS= read -r remote; do
              url=$(git remote get-url "$remote" 2>/dev/null) || continue
              repo=$(extract_repo "$url")
              [[ -z "$repo" ]] && continue
              [[ "$repo" == "$source_repo" ]] && continue
              remotes+="$remote  ($repo)"$'\n'
          done < <(git remote)

          if [[ -z "$remotes" ]]; then
              echo "No other GitHub remotes found to relay to."
              echo "Add a remote first: git remote add <name> <github-url>"
              sleep 2
              exit 1
          fi

          # Pick target via fzf
          selection=$(printf '%s' "$remotes" | fzf --prompt="Relay #$issue_number to > " --height=10 --reverse)
          [[ -z "$selection" ]] && exit 0

          target_repo=$(echo "$selection" | sed -E 's/.*\(([^)]+)\)/\1/')

          # Read source issue title and body
          echo "Reading issue #$issue_number from $source_repo..."
          issue_title=$(GH_TOKEN="$source_token" gh issue view "$issue_number" --repo "$source_repo" --json title -q '.title')
          body=$(GH_TOKEN="$source_token" gh issue view "$issue_number" --repo "$source_repo" --json body -q '.body')

          # Find account with access to target
          target_token=""
          for account in $(gh auth status 2>&1 | grep "Logged in to" | sed -E 's/.*account ([^ ]+) .*/\1/'); do
              token=$(gh auth token --user "$account" 2>/dev/null) || continue
              if GH_TOKEN="$token" gh api "repos/$target_repo" --jq '.full_name' >/dev/null 2>&1; then
                  target_token="$token"
                  echo "Using account: $account"
                  break
              fi
          done

          if [[ -z "$target_token" ]]; then
              echo "No account has access to $target_repo!"
              sleep 2
              exit 1
          fi

          # Create issue on target with provenance footer
          echo "Relaying to $target_repo..."
          relay_body=$(printf '%s\n\n---\n_Relayed from %s#%s_' "$body" "$source_repo" "$issue_number")
          new_url=$(GH_TOKEN="$target_token" gh issue create \
              --repo "$target_repo" \
              --title "$issue_title" \
              --body "$relay_body")
          echo "Done! $new_url"
          sleep 2
        '';
      };

      # Main dashboard launcher with account auto-detection
      gh-relay = (pkgs.writeShellApplication {
        name = "gh-relay";
        runtimeInputs = with pkgs; [ git gh coreutils gnused ];
        text = ''
          ${extractRepoFn}

          # Fall back to static config outside a git repo
          if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
              echo "Not inside a Git repository. Launching default gh-dash..."
              exec gh dash
          fi

          # Account selection: manual override or auto-detect from remote
          if [[ -n "''${1:-}" ]]; then
              token=$(gh auth token --user "$1" 2>/dev/null) || { echo "Account '$1' not found. Run 'gh auth status' to list accounts."; exit 1; }
              export GH_TOKEN="$token"
              echo "Using account: $1"
          else
              first_repo=""
              for remote in $(git remote); do
                  url=$(git remote get-url "$remote")
                  first_repo=$(extract_repo "$url")
                  [[ -n "$first_repo" ]] && break
              done

              if [[ -n "$first_repo" ]]; then
                  for account in $(gh auth status 2>&1 | grep "Logged in to" | sed -E 's/.*account ([^ ]+) .*/\1/'); do
                      token=$(gh auth token --user "$account" 2>/dev/null) || continue
                      if GH_TOKEN="$token" gh api "repos/$first_repo" --jq '.full_name' >/dev/null 2>&1; then
                          export GH_TOKEN="$token"
                          echo "Using account: $account (has access to $first_repo)"
                          break
                      fi
                  done
              fi
          fi

          TEMP_CONFIG=$(mktemp /tmp/gh_dash_dynamic.XXXXXX.yml)
          trap 'rm -f "$TEMP_CONFIG"' EXIT

          # Build dashboard configuration from local git remotes
          {
              echo "prSections:"
              for remote in $(git remote); do
                  url=$(git remote get-url "$remote")
                  repo=$(extract_repo "$url")
                  if [[ -n "$repo" ]]; then
                      echo "  - title: \"PR: $remote ($repo)\""
                      echo "    filters: is:open repo:$repo"
                  fi
              done

              echo "issuesSections:"
              for remote in $(git remote); do
                  url=$(git remote get-url "$remote")
                  repo=$(extract_repo "$url")
                  if [[ -n "$repo" ]]; then
                      echo "  - title: \"Issues: $remote ($repo)\""
                      echo "    filters: is:open repo:$repo"
                  fi
              done

              cat << 'RELAY_EOF'
          keybindings:
            issues:
              - key: C
                command: gh-relay-issue {{.IssueNumber}} {{.RepoName}}
          pager:
            diff: delta
          defaults:
            preview:
              open: true
              width: 60
            prsLimit: 20
            issuesLimit: 20
          confirmQuit: true
          RELAY_EOF
          } > "$TEMP_CONFIG"

          gh dash --config "$TEMP_CONFIG"
        '';
      }).overrideAttrs { pname = "gh-relay"; };
    in
    {
      options.modules.${parent}.${module} = {
        enable = lib.mkEnableOption "Enable ${parent}:${module} configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.gh-dash = {
          enable = true;
          settings = {
            # PR dashboard
            prSections = [
              {
                title = "My PRs";
                filters = "is:open author:@me";
                layout.author.hidden = true;
              }
              {
                title = "Review Requests";
                filters = "is:open review-requested:@me";
              }
              {
                title = "VolkerWessels";
                filters = "is:open org:VolkerWessels";
              }
            ];

            # Issue dashboard
            issuesSections = [
              {
                title = "My Issues";
                filters = "is:open author:@me";
              }
              {
                title = "Assigned";
                filters = "is:open assignee:@me";
              }
            ];

            defaults = {
              prsLimit = 20;
              issuesLimit = 20;
              preview = {
                open = true;
                width = 60;
              };
            };

            # Use delta for diffs (matches terminal.delta config)
            pager.diff = "delta";

            confirmQuit = true;
          };
        };

        # gh-relay-issue needs to be in PATH for the keybinding to find it
        packages = [ gh-relay-issue ];

        # Register gh-relay as a gh extension so `gh relay` works
        programs.gh.extensions = [ gh-relay ];
      };
    };
}
