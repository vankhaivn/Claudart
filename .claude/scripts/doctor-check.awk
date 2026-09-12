# Mechanical, deliberately limited readers for doctor-check.sh. The output
# separator is ASCII file separator; source text is never copied to findings.
BEGIN {
  FS = "\034"; OFS = "\034"
  nrequired = split(required_keys, requested, " ")
  for (i = 1; i <= nrequired; i++) if (requested[i] != "") required[requested[i]] = 1
}
function finding(level, code, line, message) {
  print "F", level, code, line, message
}
function candidate(line, target, kind) {
  print "L", line, target, kind
}
function trim(s) {
  sub(/^[ \t\r]+/, "", s); sub(/[ \t\r]+$/, "", s); return s
}
function scalar(s) {
  s = trim(s)
  return s != "" && (s ~ /^"([^"\\]|\\.)*"$/ ||
    s ~ /^\047([^\047]|\047\047)*\047$/ ||
    (s !~ /^[?:,\[\]{}#&*!|>"\047%@`-]/ &&
     s !~ /:[ \t]/ && s !~ /[ \t]#/ &&
     s !~ /^(true|false|null|~|[0-9]+)$/))
}
function flow(s) {
  s = trim(s)
  return s ~ /^\[.*\]$/ && s !~ /[{}]/
}
function frontmatter(line,    s,k,v,a) {
  if (NR == 1) {
    if (line != "---") { finding("ERROR", "D301", 1, "missing YAML frontmatter"); fm = -1 }
    else fm = 1
    return
  }
  if (fm != 1) return
  if (pending_key != "" && trim(line) != "" && line !~ /^[ \t]*#/) {
    if (line == "---" || line ~ /^[A-Za-z_][A-Za-z_0-9-]*[ \t]*:/) {
      if (pending_array) finding("ERROR", "D305", pending_line, "required metadata needs a flow array")
      else finding("ERROR", "D307", pending_line, "required metadata needs a scalar")
    } else {
      if (pending_array) finding("WARNING", "D306", pending_line, "array syntax needs review")
      else finding("WARNING", "D308", pending_line, "scalar syntax needs review")
    }
    pending_key = ""
  }
  if (line == "---") { fm = 2; return }
  if (line ~ /^[ \t]*#/ || trim(line) == "") return
  if (line !~ /^[A-Za-z_][A-Za-z_0-9-]*[ \t]*:/) {
    finding("WARNING", "D304", NR, "frontmatter syntax needs review")
    uncertain = 1
    return
  }
  s = line; sub(/:.*/, "", s); k = trim(s)
  v = line; sub(/^[^:]*:/, "", v); v = trim(v)
  if (seen[k]++) {
    if (k in required) finding("ERROR", "D302", NR, "duplicate required metadata key")
    else finding("WARNING", "D304", NR, "duplicate extra metadata key needs review")
  }
  if (k in required) {
    if (k == "paths" || k == "tags") {
      if (v == "") { pending_key=k; pending_array=1; pending_line=NR }
      else if (v ~ /^-/) finding("ERROR", "D305", NR, "required metadata needs a flow array")
      else if (v !~ /^[\[{>|!&*]/ && !flow(v))
        finding("ERROR", "D305", NR, "required metadata needs a flow array")
      else if (!flow(v)) finding("WARNING", "D306", NR, "array syntax needs review")
    } else if (v == "") {
      pending_key=k; pending_array=0; pending_line=NR
    } else if (v ~ /^\[/ || v ~ /^\{/) {
      finding("ERROR", "D307", NR, "required metadata needs a scalar")
    } else if (!scalar(v)) {
      finding("WARNING", "D308", NR, "scalar syntax needs review")
    }
  }
}
function remove_comments(s,    a,b) {
  while (1) {
    if (comment) {
      b = index(s, "-->")
      if (!b) return ""
      s = substr(s, b + 3); comment = 0
    }
    a = index(s, "<!--")
    if (!a) return s
    b = index(substr(s, a + 4), "-->")
    if (b) s = substr(s, 1, a - 1) " " substr(s, a + 4 + b + 2)
    else { comment = 1; return substr(s, 1, a - 1) }
  }
}
function remove_code(s,    out,i,j,n,run,ending) {
  out = ""; i = 1
  while (i <= length(s)) {
    if (substr(s,i,1) != "`") { out = out substr(s,i,1); i++; continue }
    j = i; while (substr(s,j,1) == "`") j++
    n = j-i; run = substr(s,i,n); ending = index(substr(s,j),run)
    if (ending) { out = out " "; i = j+ending+n-1 }
    else { out = out substr(s,i,n); i = j }
  }
  return out
}
function markdown(line,    s,p,c,fencechar,fencelen,rest,m,t,q,r,beg,depth,j,start,ch,escaped,example) {
  s = line
  # CommonMark fenced blocks: up to three spaces, backticks or tildes,
  # closing fence of the same character with at least the opening length.
  if (match(s,/^ {0,3}(```+|~~~+)/)) {
    m = substr(s,RSTART,RLENGTH); sub(/^ */, "", m)
    c = substr(m,1,1)
    if (fence == "") { fence=c; width=length(m); return }
    if (fence == c && length(m) >= width && trim(substr(s,RSTART+RLENGTH)) == "") {
      fence=""; width=0
    }
    return
  }
  if (fence != "") return
  s = remove_code(remove_comments(s))
  if (s == "") return
  example = (s ~ /[Ff]or example|[Ee]xample:|[Ee]\.g\./)
  # Reference-style definition at the start of a content line.
  if (match(s,/^[ \t]{0,3}\[[^]]+\]:[ \t]*/)) {
    t=trim(substr(s,RSTART+RLENGTH))
    if (substr(t,1,1)=="<") {
      q=index(t,">")
      if (q) {
        if (example) finding("WARNING","D206",NR,"example reference needs review")
        else candidate(NR,substr(t,1,q),"link")
      }
    } else {
      split(t,a,/[ \t]/)
      if (example) finding("WARNING","D206",NR,"example reference needs review")
      else candidate(NR,a[1],"link")
    }
  }
  # Locate each ]( opener, then balance destination parentheses. This avoids
  # turning a valid path like guide(v2).md into a definite broken target.
  rest=s
  while (match(rest,/\[[^]]+\]\(/)) {
    start=RSTART+RLENGTH; depth=1; escaped=0
    for (j=start; j<=length(rest); j++) {
      ch=substr(rest,j,1)
      if (escaped) { escaped=0; continue }
      if (ch=="\\") { escaped=1; continue }
      if (ch=="(") depth++
      else if (ch==")") { depth--; if (depth==0) break }
    }
    if (depth==0) {
      t=substr(rest,start,j-start)
      if (example) finding("WARNING","D206",NR,"example reference needs review")
      else candidate(NR,t,"link")
      rest=substr(rest,j+1)
    } else {
      finding("WARNING","D205",NR,"complex Markdown link syntax needs review")
      rest=substr(rest,start)
    }
  }
  if (layer != "claude") return
  rest=s
  while (match(rest,/@[A-Za-z0-9._\/-]+\.md/)) {
    m=substr(rest,RSTART+1,RLENGTH-1)
    beg=RSTART
    if (beg == 1 || substr(rest,beg-1,1) !~ /[A-Za-z0-9._\/-]/)
      if (example) finding("WARNING","D206",NR,"example import needs review")
      else candidate(NR,m,"import")
    rest=substr(rest,RSTART+RLENGTH)
  }
}
{
  if (mode == "meta") frontmatter($0)
  else if (mode == "markdown") markdown($0)
}
END {
  if (mode != "meta") exit
  if (NR == 0) finding("ERROR", "D301", 1, "missing YAML frontmatter")
  if (pending_key != "") {
    if (pending_array) finding("ERROR", "D305", pending_line, "required metadata needs a flow array")
    else finding("ERROR", "D307", pending_line, "required metadata needs a scalar")
  }
  if (fm == 1) finding("ERROR", "D303", NR > 0 ? NR : 1, "unterminated YAML frontmatter")
  if (fm == 2) {
    for (k in required) if (!(k in seen)) {
      if (uncertain) finding("WARNING", "D310", 1, "required metadata key may be missing: " k)
      else finding("ERROR", "D309", 1, "missing required metadata key " k)
    }
  }
}
