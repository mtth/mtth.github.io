# First post

## A new subtitle

And some text.

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod
tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At
vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd
gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.

```javascript
/* jshint node: true, esversion: 6 */

'use strict';

const avro = require('../../lib'),
      path = require('path');


/**
 * Load the protocol from its IDL file.
 *
 * @param cb(err, protocol) {Function} Callback, called with the parsed
 * protocol as second argument (and eventual error as first).
 */
function loadProtocol(cb) {
  const idlPath = path.join(__dirname, 'Logger.avdl');
  avro.assemble(idlPath, {oneWayVoid: true}, (err, attrs) => {
    if (err) {
      cb(err);
      return;
    }

    const logicalTypes = {'timestamp-millis': DateType};
    let protocol;
    try {
      protocol = avro.parse(attrs, {logicalTypes});
    } catch (err) {
      cb(err);
      return;
    }
    cb(null, protocol);
  });
}

/**
 * Custom class used to serialize JavaScript date objects.
 */
class DateType extends avro.types.LogicalType {
  _fromValue(val) { return new Date(val); }
  _toValue(val) { return +val; }
}


module.exports = {
  loadProtocol: loadProtocol
};
```
