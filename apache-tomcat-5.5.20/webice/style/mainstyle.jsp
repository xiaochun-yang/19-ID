<html>


<head>
   <title>Test Web-Ice stylesheet</title>

   <link rel="stylesheet" href="mainstyle.css" type="text/css">

</head>
<body>
<p>Normal paragraph</p>

<h1>h1 title</h1>
<h2>h2 title</h2>
<h3>h3 title</h3>
<h4>h4 title</h4>

<p class="mainBody">Paragraph with class mainBody. This is the same as
plain body, probably unnecessary?</p>

<p>
<a id="help" href="mainstyle.jsp">i</a> Information button (link
with id help)
<p>
<a class="a_selected" href="mainstyle.jsp"><span
id="help">Help</span></a> Help button (link enclosing span with
id). The link is class="a_selected"(to remove the underline)

<h2>Boom's classes</h2>

<p class="toolbar_body">Paragraph class toolbar-body</p>
<a class="tab selected">a class tab selected</a>
<a class="tab unselected">a class tab unselected </a>
<a class="tab_right">a class tab_right</a><br>

Gradient background tool: <a href="http://www.grsites.com/textures/red001.shtml">http://www.grsites.com/textures/red001.shtml</a>

<p><a class="a_selected" href="mainstyle.jsp">Class a_selected link</a>
and <a class="a_unselected" href="mainstyle.jsp">Class a_unselected
link</a>. The a_unselected displays underlined text when hovering with
mouse</p>

<ul>
<li class="p">List item with class p (note extra space to next item)</li>

<li><a href="mainstyle.jsp">Normal link</a>
<li><span class="error">Span with class error</span></li>

</ul>

<table class="autoindex"><caption>Autoindex class table:</caption>
<tr><th colspan=2>Table Header 1</th></tr>
<tr><td>Data</td><td> Data </td></tr>
</table>


</body>
</html>
