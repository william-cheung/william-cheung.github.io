<%inherit file="site.mako" />
<div class="content">
<div class="column">
<h1>Posts by Date</h1>
% for year in years:
<h2>${year}</h2>
% for post in posts[year]:
  <%include file="post_box.mako" args="post=post" />
% endfor
% endfor
</div>
</div>