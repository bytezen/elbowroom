/* ports.js - Chrome 55.0.2883.95 (64-bit)

   It is assumed that "this.Elm" is set
   and valid for this IIFE (i.e. "Window.Elm.Shanghai"
   was set by Shanghai.js beforehand).
 */
; (function() {

  function connectElmWorker(elm) {
    function logDockedCapacity (value) {
      console.log(
        '[' + (new Date).toISOString() + ']: ' + value
      );
    }

    /*  "Elm.Shanghai" as in "module Shanghai"
           from file "Shanghai.elm""
           compiled into file "Shanghai.js.
     */
    let elmWorker = elm.Shanghai.worker();

    // log docked capacity changes
    elmWorker.ports.totalCapacity.subscribe(logDockedCapacity);

    return elmWorker;
  }

  function dock(worker, name, capacity) {
    worker.ports.incomingShip.send({
      name: name,
      capacity: capacity
    });
  }

  function sail(worker, name) {
    worker.ports.outgoingShip.send(name);
  }

  function scheduleActions(shanghai) {
    function dockAt(worker, name, capacity){
      return dock.bind(null, worker, name, capacity);
    }
    function sailFrom(worker, name) {
      return sail.bind(null, worker, name);
    }
    function at(delay, func) {
      setTimeout(func, delay);
    }

    const mary = 'Mary Mærsk',
          emma = 'Emma Mærsk';

    // send some ships to the port of Shanghai
    at(500, dockAt(shanghai, mary, 18270));
    at(1000, dockAt(shanghai, emma, 15500));

    // have these ships leave the port of Shanghai
    at(1500, sailFrom(shanghai, mary));
    at(2000, sailFrom(shanghai, emma));
  }


  const moduleName = 'shanghaiPorts';
  let elmWorker = connectElmWorker(this.Elm);
  scheduleActions(elmWorker);

  if (typeof this[moduleName] === 'undefined') {
    this[moduleName] = {
      dock: dock.bind(null, elmWorker),
      sail: sail.bind(null, elmWorker),
      shanghai: elmWorker
    };
  }

}).call(this);