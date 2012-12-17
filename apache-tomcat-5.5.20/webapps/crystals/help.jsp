<HTML>
<HEADER>
<TITLE>Sample Database</TITLE>
</HEADER>
<BODY>

<%@include file="config.jsp" %>
<%@include file="pageheader.jsp" %>

<H2>Using the Web interface of the Sample Database</H2>

<A HREF="#v4_5">
v4.5 release note
</A>

<BR>
<A HREF="#v4_3">
v4.3 release note
</A>
<BR>

<A HREF="#downloadNetscape">
How to download an Excel file with Netscape
</A>
<BR>

<A HREF="#downloadIE">
How to download an Excel file with Microsoft Internet Explorer
</A>
<BR>

<A HREF="#edit">
How to edit an Excel spreadsheet on a SSRL beamline machine
</A>
<BR>

<A HREF="#upload">
How to upload an Excel file
</A>
<BR>

<A HREF="#bluice">
How to make the current selection visible in the BLU-ICE Screening UI
</A>
<BR>
<BR>

For more information see the manuals:
<BR>
<A HREF="http://smb.slac.stanford.edu/public/users_guide/manual/manual/Using_SSRL_Automated_Mounti.html">
High-Throughput Screening System
</A>
<BR>
<A HREF="http://smb.slac.stanford.edu/public/facilities/software/blu-ice/screen_tab.html">
BLU-ICE Screening UI
</A>
<BR>
<BR>


<HR>
<H3><A NAME="v4_5">
v4.5 release note:
</A></H3>
<ul>
<li>Puck adapter template is now available.</li>
</ul>
<BR>
<BR>


<HR>
<H3><A NAME="v4_3">
v4.3 release note:
</A></H3>
<ul>
<li>During upload, the spreadsheet maybe modified to ensure that Port, CrystalID and Directory
columns are valid.</li>
<li>Some crystal data in the uploaded spreadsheet can be edited and saved using web browser.</li>
<li>Crystal scoring results generated during screening are stored in the uploaded spreadsheet.</li>
<li>Both modified and original spreadsheet are downloadable.</li>
<li>User can assign a spreadsheet to a beamline in a single step using the web browser. The
spreadsheet will be loaded into BluIce automatically.</li>
</ul>
<BR>
<BR>

<HR>
<H3><A NAME="downloadNetscape">
How to download an Excel file with Netscape:
</A></H3>
On the Screening System Database Page <strong>right-click</strong> the hyperlink "Download Excel file"
or "Download Original Excel File" for the corresponding cassette. "Download Excel file" downloads
the spreadsheet that is edited via the web browser and contains crystal scoring results.
"Download Original Excel File" downloads the original spreadsheet that the user uploaded.
<BR>
In the popup menu select "Save Link As ...".
<BR>
In the dialog "Save As..." select "Source" as the <strong>Format of the Saved Document</strong>,
navigate to the correct directory and press "OK".
<BR>
<BR>

<HR>
<H3><A NAME="downloadIE">
How to download an Excel file with Microsoft Internet Explorer:
</A></H3>
On the Screening System Database Page <strong>right-click</strong> the hyperlink "Download Excel file"
or "Download Original Excel File"for the corresponding
cassette.
<BR>
In the popup menu select "Save Target As ...".
<BR>
In the dialog "Save As..." select "Microsoft Excel Worksheet" as the <strong>Save as type</strong>,
navigate to the correct directory and press "Save".
<BR>
<BR>

<HR>
<H3><A NAME="#edit">
How to edit an Excel spreadsheet on a SSRL beamline machine via the web browser:
</A></H3>
Click "View/Edit" link on the cassette list page.
<BR>
<BR>


<HR>
<H3><A NAME="#edit">
How to edit an Excel spreadsheet on a SSRL beamline machine using MS Excel or Star Office:
</A></H3>
If you want to use Microsoft software to edit the spreadsheet during you beamtime at SSRL,
you will have to bring your own laptop.
<BR>
Alternatively, you can run Netscape or Mozilla from the SGI beamline computers and
launch StarOffice from the "Download Excel File..." link in the screening database interface.
<BR>
You can also save the file to your own directories  as described <A HREF="#downloadNetscape"> above</A> and
run StarOffice from the Unix command line:
<BR>
<strong>
&gt; soffice 'filename.xls'
</strong>
<BR>
The first time you run this program,
you will get some pop-up windows to generate some files in your home directory.
Select the defaults and click on "next" until the installation is complete.
<BR>
Once you have finished editing the spreadsheet,
save it to your home or data directory as a Microsoft Excel 97/2000/XP file type.
<BR>
For more information on this software, see the
<A HREF="http://www.openoffice.org/">
OpenOffice</A> site.
<BR>
<BR>

<HR>
<H3><A NAME="upload">
How to upload an Excel file:
</A></H3>
Make sure that the upload file is in Microsoft Excel format and is based on this
<A HREF="cassette_template.xls">
template</A>.
<BR>
On Screening System Database page click the hyperlink "Upload new file..." for the corresponding
cassette.
<BR>
On the Upload Excel File page click the "Browse" button.
<BR>
In the dialog "Choose File" make sure that the <strong>Filter</strong> is "*.*" or "*.xls", navigate to the Excel file, select the Excel file and press "Open".
<BR>
Enter the correct spreadsheet name.
Please note that generally the spreadsheet name is not the same as the file name.
In most cases is the spreadsheet name "Sheet1" but Microsoft Excel gives you the option to change it.
Please use only alphanumeric characters for the spreadsheet name and do not use any space characters.
<BR>
Click the "Upload" button.
<BR>
<BR>

<HR>
<H3><A NAME="bluice">
How to make the current selection visible in the BLU-ICE Screening UI:
</A></H3>
On <A HREF="CassetteInfo.jsp">Screening System Database</A> page: Make sure that you have selected the correct beamline.
<BR>
In the screening UI at the beamline: <strong>Dismount</strong> the current crystal and press the <strong>"Update"</strong> button.
<BR>
<BR>


<HR>
<A HREF="CassetteInfo.jsp">
Back</A> to the Screening System Database.
<BR>
<BR>

</BODY>
</HTML>

