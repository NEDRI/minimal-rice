// A value pulled to `target` by a damped spring, as Isle's spring.js: it can be retargeted
// mid-flight and keeps its speed, so the island never jolts. ~3.5 % overshoot, at rest in ~0.6 s.
import QtQuick

QtObject {
    id: spring

    property real target: 0
    property real value: 0
    property real velocity: 0
    property real stiffness: 155
    property real damping: 18
    // at rest within a quarter pixel, slower than 2 px/s; a 0..1 value sets a finer `precision`
    property real precision: 0.25
    readonly property bool settled: Math.abs(value - target) < precision && Math.abs(velocity) < precision * 8

    // jumps to `v` without motion; `target` keeps its binding
    function reset(v) {
        value = v;
        velocity = 0;
    }

    Component.onCompleted: value = target

    function step(dt) {
        let remaining = Math.min(Math.max(dt, 0), 0.25);
        let v = value, vel = velocity;
        while (remaining > 0 && !(Math.abs(v - target) < precision && Math.abs(vel) < precision * 8)) {
            const h = Math.min(remaining, 1 / 240);
            vel += (-stiffness * (v - target) - damping * vel) * h;
            v += vel * h;
            remaining -= h;
        }
        // land exactly on the target once at rest, so nothing stays a fraction of a pixel off
        if (Math.abs(v - target) < precision && Math.abs(vel) < precision * 8) {
            v = target;
            vel = 0;
        }
        velocity = vel;
        value = v;
    }
}
