#ifndef TOUCHBARBUTTON_H
#define TOUCHBARBUTTON_H

#include <QQuickItem>
class TouchBarButton : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    QString m_title;

public:
    TouchBarButton();
    ~TouchBarButton();
    QString title() const;
    void* onPressedBlock() { return m_onPressedBlock; }
signals:
    void titleChanged(QString title);
    void pressed();
public slots:
    void setTitle(QString title);
private:
    void *m_onPressedBlock;
};

#endif // TOUCHBARBUTTON_H
