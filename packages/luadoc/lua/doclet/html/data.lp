<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
	<head>
	    <%if doc.description.title == "" then%>
			<title><%=doc.description.package%></title>
		<%else%>
	    	<title><%=doc.description.title%></title>
	    <%end%>
	    <link rel="stylesheet" href="<%=luadoc.link('luadoc.css', 'files/data.lua')%>" type="text/css" />
		<!--meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/-->
	</head>

	<body>
		<div id="container">
			<div id="product">
				<div id="product_logo">
					<a href="<%="http://www.terrame.org"%>">
					<img src='<%="../img/terrame.png"%>'/><br/></div></a>
				<div id="product_name"><big><b></b></big></div>
				<div id="product_description"></div>
			</div> <!-- id="product" -->

			<div id="main">
				<div id="navigation">
					<%=luadoc.include("menu.lp", { doc = doc, mdata = true })%>
				</div> <!-- id="navigation" -->

				<div id="content">
					<%
					local function isProject(data)
						return (type(data.file[1]) == "string" and data.file[1]:endswith(".tview"))
					end

					doc.projectFiles = {}
					doc.dataFiles = {}

					if not options.nofiles and doc.mdata then
						for _, data in ipairs(doc.mdata) do
							if isProject(data) then
								table.insert(doc.projectFiles, data)
							else
								table.insert(doc.dataFiles, data)
							end
						end
					end
					%>
					<%local function buildIndex(mdata)%>
						<table class="file_list">
						<%for _, data in ipairs(mdata) do%>
							<tr>
								<td class="name"><a href = "#<%=data.file[1]%>"><%=data.file[1]%></a></td>
								<td class="summary"><%= data.shortsummary or "" %></td>
							</tr>
						<%end%>
						</table>
					<%end%>

					<%local function buildAttributes(mdata, borderTop)%>
						<%if type(borderTop) == "number" then%>
							<%borderTop = "border-top: "..borderTop.."px"%>
							<%borderTop = "style=".."\""..borderTop.."\""%>
						<%else%>
							<%borderTop = ""%>
						<%end%>

						<dl class="function">
							<%for _, data in ipairs(mdata) do%>
								<dt<%=borderTop%>><h2><a name="<%=data.file[1]%>" href= <%="../../data/"..data.file[1]%>><%=data.file[1]%></a></h2></dt>

								<% if data.image then %>
									<% loc = "../../images/"..tostring(data.image) %>
									<center><img src=<% =loc %> ></center><br><br>
								<%end%>
								<%if data.summary then%>
									<%=data.summary%>
								<%else%>
									<font color="red"><%="undefined"%></font>
								<%end%>
								<dd>
								<%if #data.file > 1 then%>
									<br><b>Files: </b>
									<%for pos, f in ipairs(data.file) do%>
										<%if pos<#data.file then%>
											<%=f..", "%>
										<%else%>
											<%=f%>
										<%end%>
									<%end%>
								<%end%>

								<%if data.source then%>
									<br><b>Source: </b>
									<%= httpLink(data.source)%>
								<%end%>

								<%if data.projection then%>
									<br><b>Projection: </b><%=data.projection%>
								<%end%>

								<%if data.representation then%>
									<br><b>Representation: </b><%=data.representation%>
								<%end%>

								<%if data.quantity then%>
									<br><b>Quantity: </b><%=data.quantity%>
								<%end%>

								<%if data.bands then%>
									<br><b>Bands: </b><%=data.bands%>
								<%end%>

								<%if data.separator then%>
									<br><b>Separator: </b><%="\""..data.separator.."\""%>
								<%end%>

								<%if data.reference then%>
									<br><b>Reference: </b><%=data.reference%>
								<%end%>

								<%if data.attributes then%>
									<table class="arg_tab">
									<tr><td><b><%if data.bands then%>Band<%else%>Attribute<%end%>
									</b></td><td><b>Type</b></td><td><b>Description</b></td></tr>
									<%if data.attributes[1] == "_incompatible_" then%>
										<tr>
										<td><font color="red">Incompatible sizes</font></td>
										<td><font color="red">Incompatible sizes</font></td>
										<td><font color="red">Incompatible sizes</font></td>
										</tr>
									<%else%>
										<% for j = 1,#data.attributes do %>
											<%if data.bands then%>
												<tr><td><%=data.attributes[j]%></td><td><%="\""..tostring(data.types[j]).."\""%></td><td><%=data.description[j]%></td></tr>
											<%else%>
											<tr><td><%="\""..data.attributes[j].."\""%></td><td><%="\""..tostring(data.types[j]).."\""%></td><td><%=data.description[j]%></td></tr>
											<%end%>
										<%end%>
									<%end%>
									</table>
								<%end%>

								<%if data.layers then%>
									<table class="arg_tab">
									<tr><td><b>Layer</b></td><td><b>File</b></td><td><b>Description</b></td></tr>
									<% for j = 1,#data.layers do %>
									<tr><td><%="\""..data.layers[j].layer.."\""%></td><td><a href = "#<%=data.layers[j].file%>"><%=data.layers[j].file%></a></td><td><%=data.layers[j].description%></td></tr>
									<%end%>
									</table>
								<%end%>

								</dd>
							<%end%>
						</dl>
					<%end%>

					<!-- tview -->
					<%if #doc.projectFiles > 0 then%>
						<h1>Projects</h1>
						<%buildAttributes(doc.projectFiles, 0)%>
					<%end%>
					<!-- /tview -->
					<!-- data -->
					<%if #doc.dataFiles > 0 then%>
						<h1>Data</h1>
						<%buildIndex(doc.dataFiles)%>
						<%buildAttributes(doc.dataFiles)%>
					<%end%>
					<!-- /data -->
				</div>
				<!-- id="content" -->
			</div> <!-- id="main" -->

			<div id="about">
				<p><a href="http://validator.w3.org/check?uri=referer"><img src="http://www.w3.org/Icons/valid-xhtml10" alt="Valid XHTML 1.0!" height="31" width="88" /></a></p>
			</div> <!-- id="about" -->

		</div> <!-- id="container" -->	
	</body>
</html>

