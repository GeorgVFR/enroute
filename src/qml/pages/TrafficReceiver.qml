/***************************************************************************
 *   Copyright (C) 2019-2021 by Stefan Kebekus                             *
 *   stefan.kebekus@gmail.com                                              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

import QtQml 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

import enroute 1.0
import "../dialogs"
import "../items"

Page {
    id: trafficReceiverPage
    title: qsTr("Traffic Receiver")

    header: StandardHeader { }

    ScrollView {
        id: view

        anchors.fill: parent
        clip: true

        anchors.topMargin: Qt.application.font.pixelSize
        anchors.bottomMargin: Qt.application.font.pixelSize
        anchors.leftMargin: Qt.application.font.pixelSize
        anchors.rightMargin: Qt.application.font.pixelSize

        contentWidth: width

        // The visibility behavior of the vertical scroll bar is a little complex.
        // The following code guarantees that the scroll bar is shown initially. If it is not used, it is faded out after half a second or so.
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: (height < contentHeight) ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded

        ColumnLayout {
            width: view.width
            implicitWidth: view.width

            Label {
                Layout.fillWidth: true

                text: qsTr("<h3>Status</h3>")
                font.bold: true
                textFormat: Text.MarkdownText
            }

            Label { // Status
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4

                text:  {
                    if (flarmAdaptor.status == FLARMAdaptor.Disconnected)
                        return qsTr("Not connected to a traffic receiver.")
                    if (flarmAdaptor.status == FLARMAdaptor.Connecting)
                        return qsTr("Trying to connect to traffic receiver at IP address 192.168.1.1, port 2000 …")
                    if (flarmAdaptor.status == FLARMAdaptor.Connected)
                        return qsTr("Connected to traffic receiver at IP address 192.168.1.1, port 2000. Waiting for data …")
                    return qsTr("Connected to traffic receiver at IP address 192.168.1.1, port 2000. Receiving traffic information …")
                }

                wrapMode: Text.WordWrap

                bottomPadding: 0.2*Qt.application.font.pixelSize
                topPadding: 0.2*Qt.application.font.pixelSize
                leftPadding: 0.2*Qt.application.font.pixelSize
                rightPadding: 0.2*Qt.application.font.pixelSize

                leftInset: -4
                rightInset: -4

                // Background color according to METAR/FAA flight category
                background: Rectangle {
                    border.color: "black"
                    color: (flarmAdaptor.status === FLARMAdaptor.Receiving) ? "green" : "red"
                    opacity: 0.2
                    radius: 4
                }
            }

            Label { // Error string
                Layout.fillWidth: true

                text:  "<h3>" + qsTr("Last error") + "</h3><p>" + flarmAdaptor.errorString + "</p>"
                visible: flarmAdaptor.errorString !== ""

                wrapMode: Text.WordWrap
                textFormat: Text.RichText

                bottomPadding: 0.2*Qt.application.font.pixelSize
                topPadding: 0.2*Qt.application.font.pixelSize
            }

            Label {
                Layout.fillWidth: true

                text:   {
                    if (flarmAdaptor.status == FLARMAdaptor.Disconnected)
                        return ("
<h3>How to connect your device to the traffic receiver</h3>

<ul style=\"margin-left:-25px;\">
<li>Make sure that your traffic receiver has an integrated Wi-Fi interface that acts as a wireless access point. Bluetooth devices are currently not supported.</li>
<li>Use the 'WLAN Settings' of your device to enter the WLAN network deployed by your traffic receiver.</li>
<li>Once your device has entered the WLAN network, use the button at the bottom of the page to connect the <strong>Enroute Flight Navigation</strong> to the traffic data stream.</li>
</ul>
")
                    if (flarmAdaptor.status == FLARMAdaptor.Connecting)
                        return ("
<p><strong>Enroute Flight Navigation</strong> is trying to connect to the traffic receiver's data stream. If no connection has been established after a few seconds, somthing has gone wrong.</p>

<ul style=\"margin-left:-25px;\">
<li>Make sure that your device has entered the WLAN network deployed by your traffic receiver.  If not, then use the button at the bottem of the screen to abort the connection attempt.</li>
</ul>
")
                    if (flarmAdaptor.status == FLARMAdaptor.Connected)
                        return ("
<p><strong>Enroute Flight Navigation</strong> is now set up to receive traffic data. If no data arrives after a few seconds, somthing has gone wrong.</p>

<ul style=\"margin-left:-25px;\">
<li>Make sure that the device at the IP address 192.168.1.1 is indeed a traffic receiver.</li>
<li>Some traffic receivers protect the data stream with an additional password. This is currently not supported.</li>
</ul>
")
                    return ("
<p>Well done! Go flying. Give yourself a pat on the back.</p>")
                }

                textFormat: Text.RichText
                wrapMode: Text.WordWrap

            }
        }

    } // Scrollview

    footer: Pane {
        width: parent.width
        Material.elevation: 3

        ColumnLayout {
            width: parent.width

            ToolButton {
                text: {
                    if (flarmAdaptor.status === FLARMAdaptor.Disconnected)
                        return qsTr("Connect to Traffic Receiver")
                    if (flarmAdaptor.status === FLARMAdaptor.Connecting)
                        return qsTr("Abort Connection")
                    qsTr("Disconnect from Traffic Receiver")
                }

                icon.source: (flarmAdaptor.status === FLARMAdaptor.Disconnected) ? "/icons/material/ic_tap_and_play.svg" : "/icons/material/ic_cancel.svg"

                Layout.alignment: Qt.AlignHCenter
                Material.foreground: Material.accent

                enabled: !timer.running
                onClicked: {
                    if (flarmAdaptor.status == FLARMAdaptor.Disconnected)
                        flarmAdaptor.connectToTrafficReceiver()
                    else
                        flarmAdaptor.disconnectFromTrafficReceiver()
                    timer.running = true;
                }
                Timer {
                    id: timer
                    interval: 1000
                }

            }

        }
    }

} // Page