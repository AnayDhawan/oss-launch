#!/usr/bin/env bash
# detect-site.sh: is this repo publishing a website?
# Sourced, not executed directly. Companion to detect-stack.sh.
#
# Only used to decide whether to emit site files (404.html, robots.txt, sitemap.xml).
# Those are inert in a repo that publishes no site, but they are also confusing clutter,
# and a robots.txt pointing at a sitemap that 404s is worse than no robots.txt.
#
# So this is deliberately CONSERVATIVE: it returns empty whenever it is not sure. A false
# negative costs a user three files they can copy by hand; a false positive puts junk in
# every repo that happens to have a stray config file. llms.txt is written regardless,
# since it describes the project rather than a site.

detect_site_framework() {  # detect_site_framework <dir> -> framework name, or nothing
  local dir="$1"

  # A CNAME at the repo root is GitHub Pages' custom-domain marker. Unambiguous.
  [ -f "$dir/CNAME" ] && { echo "github-pages"; return; }

  # Jekyll / GitHub Pages. _config.yml is a common enough filename that it is only
  # trusted alongside a directory Jekyll actually requires.
  if [ -f "$dir/_config.yml" ] || [ -f "$dir/_config.yaml" ]; then
    if [ -d "$dir/_posts" ] || [ -d "$dir/_layouts" ] || [ -d "$dir/_includes" ] \
       || [ -f "$dir/Gemfile" ] || [ -d "$dir/docs/_posts" ]; then
      echo "jekyll"; return
    fi
  fi

  if [ -f "$dir/mkdocs.yml" ] || [ -f "$dir/mkdocs.yaml" ]; then
    echo "mkdocs"; return
  fi

  if ls "$dir"/docusaurus.config.* >/dev/null 2>&1; then echo "docusaurus"; return; fi
  if ls "$dir"/astro.config.*      >/dev/null 2>&1; then echo "astro"; return; fi

  # VitePress: a .vitepress dir anywhere shallow, or a declared dependency.
  if [ -d "$dir/.vitepress" ] || [ -d "$dir/docs/.vitepress" ]; then
    echo "vitepress"; return
  fi
  if [ -f "$dir/package.json" ] && grep -q '"vitepress"' "$dir/package.json" 2>/dev/null; then
    echo "vitepress"; return
  fi

  # Hugo. hugo.toml/config.toml alone is not enough (`config.toml` is a generic filename
  # and Hugo's own is often nested), so it needs a corroborating Hugo-only directory.
  local hugocfg
  for hugocfg in "$dir"/hugo.toml "$dir"/hugo.yaml "$dir"/hugo.yml "$dir"/hugo.json \
                 "$dir"/config.toml "$dir"/config.yaml "$dir"/config.yml; do
    [ -f "$hugocfg" ] || continue
    if [ -d "$dir/archetypes" ] || [ -d "$dir/layouts" ] || [ -d "$dir/content" ]; then
      echo "hugo"; return
    fi
  done

  # Eleventy. A config file is conventional but optional and freely renamed, so the
  # declared dependency is the firmer marker; a config file still counts on its own
  # because .eleventy.js/eleventy.config.* are Eleventy-specific names.
  if [ -f "$dir/package.json" ] && grep -q '"@11ty/eleventy"' "$dir/package.json" 2>/dev/null; then
    echo "eleventy"; return
  fi
  if [ -f "$dir/.eleventy.js" ] || [ -f "$dir/.eleventy.cjs" ] \
     || ls "$dir"/eleventy.config.* >/dev/null 2>&1; then
    echo "eleventy"; return
  fi

  # Next.js only counts when it is configured to emit a static export. A Next app that
  # is server-rendered on Vercel does not want a hand-written sitemap.xml in the repo root.
  local nextcfg
  for nextcfg in "$dir"/next.config.*; do
    [ -f "$nextcfg" ] || continue
    if grep -qE "output:[[:space:]]*['\"]export['\"]" "$nextcfg" 2>/dev/null; then
      echo "next-export"; return
    fi
  done

  # Anything else (plain gh-pages branch, hand-rolled static output, ...) is not detected
  # on purpose.
  # Add a marker here only when it is as unambiguous as the ones above.
  return 0
}
