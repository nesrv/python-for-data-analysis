(function () {
  var keywords = {
    select: 1, from: 1, where: 1, insert: 1, into: 1, values: 1, update: 1, set: 1,
    delete: 1, create: 1, or: 1, replace: 1, drop: 1, table: 1, view: 1, rule: 1,
    trigger: 1, function: 1, procedure: 1, as: 1, on: 1, to: 1, do: 1, also: 1,
    instead: 1, begin: 1, end: 1, if: 1, then: 1, else: 1, elsif: 1, return: 1,
    returns: 1, language: 1, declare: 1, case: 1, when: 1, and: 1, not: 1, null: 1,
    is: 1, in: 1, by: 1, order: 1, group: 1, having: 1, join: 1, left: 1, right: 1,
    inner: 1, outer: 1, full: 1, cross: 1, union: 1, all: 1, distinct: 1, limit: 1,
    offset: 1, with: 1, recursive: 1, primary: 1, key: 1, references: 1, foreign: 1,
    unique: 1, check: 1, default: 1, constraint: 1, alter: 1, add: 1, column: 1,
    integer: 1, int: 1, text: 1, boolean: 1, numeric: 1, timestamp: 1, date: 1,
    true: 1, false: 1, new: 1, old: 1, before: 1, after: 1, for: 1, each: 1, row: 1,
    execute: 1, call: 1, exists: 1, count: 1, sum: 1, now: 1, generated: 1, always: 1,
    identity: 1, plpgsql: 1, sql: 1, exception: 1, raise: 1, materialized: 1,
    refresh: 1, index: 1, type: 1, domain: 1, enum: 1, using: 1, between: 1, like: 1,
    ilike: 1, asc: 1, desc: 1, nulls: 1, over: 1, partition: 1, window: 1
  };

  function escapeHtml(text) {
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function highlight(source) {
    var pattern = /(--[^\n]*)|(\/\*[\s\S]*?\*\/)|('(?:''|[^'])*')|(\b\d+(?:\.\d+)?\b)|([A-Za-z_][A-Za-z0-9_]*)|([^A-Za-z0-9_']+)/g;
    var html = "";
    var match;
    var last = 0;
    while ((match = pattern.exec(source))) {
      html += escapeHtml(source.slice(last, match.index));
      var token = match[0];
      var cls = "";
      if (match[1] || match[2]) cls = "tok-com";
      else if (match[3]) cls = "tok-str";
      else if (match[4]) cls = "tok-num";
      else if (match[5] && keywords[match[5].toLowerCase()]) cls = "tok-kw";
      html += cls ? '<span class="' + cls + '">' + escapeHtml(token) + "</span>" : escapeHtml(token);
      last = match.index + token.length;
    }
    html += escapeHtml(source.slice(last));
    return html;
  }

  document.querySelectorAll("code.language-sql").forEach(function (block) {
    if (block.dataset.highlighted === "yes") return;
    block.innerHTML = highlight(block.textContent);
    block.dataset.highlighted = "yes";
  });
})();
