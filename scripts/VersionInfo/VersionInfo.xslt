<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <html>
            <head>
                <link href="bootstrap.min.css" rel="stylesheet" />
            </head>
            <body>
                <div class="container">
                    <xsl:for-each select="Servers/Server">
                        <table class="table table-striped">
                            <thead>
                                <tr>
                                    <th class="col"></th>
                                    <th class="col"></th>
                                    <xsl:for-each select="App[1]/Slot">
                                        <th class="col">
                                            <xsl:value-of select="@Name" />
                                        </th>
                                    </xsl:for-each>
                                </tr>
                            </thead>
                            <tbody>
                                <xsl:for-each select="App">
                                    <tr>
                                        <td class="col">
                                            <xsl:value-of select="parent::Server/@Name" />
                                        </td>
                                        <td class="col">
                                            <xsl:value-of select="@Name" />
                                        </td>
                                        <xsl:for-each select="Slot">
                                            <xsl:choose>
                                                <xsl:when test="@Enabled = 'True'">
                                                    <td class="col bg-success">
                                                        <xsl:value-of select="@Version" />
                                                    </td>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <td class="col bg-danger">
                                                        <xsl:value-of select="@Version" />
                                                    </td>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:for-each>
                                    </tr>
                                </xsl:for-each>
                            </tbody>
                        </table>
                    </xsl:for-each>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:transform>
