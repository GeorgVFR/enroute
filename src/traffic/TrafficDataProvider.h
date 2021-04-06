/***************************************************************************
 *   Copyright (C) 2021 by Stefan Kebekus                                  *
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

#pragma once

#include <QQmlListProperty>

#include "traffic/FLARMWarning.h"
#include "traffic/TrafficFactor.h"


namespace Traffic {

/*! \brief Traffic receiver
 *
 *  This class manages multiple TrafficDataSources. It combines the data streams,
 *  and passes data from the most relevant (if any) traffic data source on to the
 *  consumers of this class.
 *
 *  By default, it watches the following data channels:
 *
 *  - TCP connection to 192.168.1.1, port 2000
 *  - TCP connection to 192.168.10.1, port 2000
 *
 *  This class also acts as a PositionInfoSource, and passes position data (that
 *  some traffic receivers provide) on to the the consumers of this class.
 */
class TrafficDataProvider : public Positioning::PositionInfoSource_Abstract {
    Q_OBJECT

public:
    /*! \brief Default constructor
     *
     * @param parent The standard QObject parent pointer
     */
    explicit TrafficDataProvider(QObject *parent = nullptr);

    // Standard destructor
    ~TrafficDataProvider() = default;

    //
    // Methods
    //

    /*! \brief Pointer to static instance of this class
     *
     *  @returns Pointer to global instance
     */
    static TrafficDataProvider *globalInstance();

    //
    // Properties
    //

    /*! \brief Receiving data from one data source */
    Q_PROPERTY(bool receivingHeartbeat READ receivingHeartbeat NOTIFY receivingHeartbeatChanged)

    /*! \brief Getter method for property with the same name
     *
     *  @returns Property receiving
     */
    bool receivingHeartbeat() const;

    /*! \brief Getter method for property with the same name
     *
     *  @returns Property statusString
     */
    void updateStatusString();

    /*! \brief Traffic objects whose position is known
     *
     *  This property holds a list of the most relevant traffic objects, as a
     *  QQmlListProperty for better cooperation with QML. Note that only the
     *  valid items in this list pertain to actual traffic. Invalid items should
     *  be ignored. The list is not sorted in any way. The items themselves are
     *  owned by this class.
     */
    Q_PROPERTY(QQmlListProperty<Traffic::TrafficFactor> trafficObjects4QML READ trafficObjects4QML CONSTANT)

    /*! \brief Getter method for property with the same name
     *
     *  @returns Property trafficObjects4QML
     */
    QQmlListProperty<Traffic::TrafficFactor> trafficObjects4QML()
    {
        return QQmlListProperty(this, &m_trafficObjects);
    }

    /*! \brief Most relevant traffic object whose position is not known
     *
     *  This property holds a pointer to the most relevant traffic object whose
     *  position is not known.  This item should be ignored if invalid. The item
     *  is owned by this class.
     */
    Q_PROPERTY(Traffic::TrafficFactor *trafficObjectWithoutPosition READ trafficObjectWithoutPosition CONSTANT)

    /*! \brief Getter method for property with the same name
     *
     *  @returns Property trafficObjectWithoutPosition
     */
    Traffic::TrafficFactor *trafficObjectWithoutPosition()
    {
        return m_trafficObjectWithoutPosition;
    }

    /*! \brief Current traffic warning
     *
     *  This property holds the current traffic warning.  The traffic warning is updated regularly and set
     *  to an invalid warning (i.e. one with alarmLevel == -1) after a certain period.
     */
    Q_PROPERTY(Traffic::FLARMWarning flarmWarning READ flarmWarning NOTIFY flarmWarningChanged)

    /*! \brief Getter method for property with the same name
     *
     *  @returns Property flarmWarning
     */
    Traffic::FLARMWarning flarmWarning() const
    {
        return m_FLARMWarning;
    }

signals:
    /*! \brief Notifier signal */
    void receivingHeartbeatChanged(bool);

    /*! \brief Notifier signal */
    void flarmWarningChanged(const Traffic::FLARMWarning &warning);

public slots:
    /*! \brief Start attempt to connect to traffic receiver
     *
     * If this class is connected to a traffic receiver, this method does nothing.
     * Otherwise, it stops any ongoing connection attempt and starts a new attempt
     * to connect to a potential receiver.
     */
    void connectToTrafficReceiver();

    /*! \brief Disconnect from traffic receiver
     *
     * This method stops any ongoing connection or connection attempt.
     */
    void disconnectFromTrafficReceiver();

private slots:
    // Called if one of the sources indicates a heartbeat change
    void onSourceHeartbeatChanged();

    // Called if one of the sources reports traffic (position unknown)
    void onTrafficFactorWithPosition(const Traffic::TrafficFactor &factor);

    // Called if one of the sources reports traffic (position known)
    void onTrafficFactorWithoutPosition(const Traffic::TrafficFactor &factor);

    // Resetter method
    void resetFLARMWarning();

    // Setter method
    void setFLARMWarning(const Traffic::FLARMWarning& warning);

private:
    // Targets
    QList<Traffic::TrafficFactor *> m_trafficObjects;
    QPointer<Traffic::TrafficFactor> m_trafficObjectWithoutPosition;

    QList<QPointer<Traffic::TrafficDataSource_Abstract>> m_dataSources;

    // Property cache
    FLARMWarning m_FLARMWarning;
    QTimer m_FLARMWarningTimer;

    // Reconnect
    QTimer reconnectionTimer;

    // Property Cache
    bool m_receiving {false};
};

}
