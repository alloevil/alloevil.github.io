---
layout: single
title: 俯卧撑记录
permalink: /workout/
---

{% assign month = site.time | date: "%Y-%m" %}
{% assign entries = site.data.workouts | where_exp: "e", "e.date | date: '%Y-%m' == month" %}

- 本月打卡天数：{{ entries | size }}

{% assign month_total = 0 %}
{% assign am_month = 0 %}
{% assign pm_month = 0 %}

{% for e in entries %}
  {% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
  {% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
  {% assign day_total = am_total | plus: pm_total %}
  {% assign month_total = month_total | plus: day_total %}
  {% assign am_month = am_month | plus: am_total %}
  {% assign pm_month = pm_month | plus: pm_total %}
{% endfor %}

- 本月总俯卧撑：{{ month_total }} 次（早：{{ am_month }} · 晚：{{ pm_month }}）

## 明细
{% for e in entries %}
{% assign am_total = 0 %}{% if e.am %}{% for r in e.am %}{% assign am_total = am_total | plus: r %}{% endfor %}{% endif %}
{% assign pm_total = 0 %}{% if e.pm %}{% for r in e.pm %}{% assign pm_total = pm_total | plus: r %}{% endfor %}{% endif %}
- {{ e.date }}{% if e.am %} · 早：{{ am_total }} 次（{{ e.am | join: ", " }}）{% endif %}{% if e.pm %} · 晚：{{ pm_total }} 次（{{ e.pm | join: ", " }}）{% endif %}{% if e.notes %} · {{ e.notes }}{% endif %}
{% endfor %}
