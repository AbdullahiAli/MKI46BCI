﻿/////////////////////////////////////////
//      BufferComm.cs
/////////////////////////////////////////

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using FieldTrip.Buffer;

namespace SDL_NET_game
{
    // Communication with the FiledTrip buffer
    class BufferComm
    {

        // Connection parametars
        static string hostname = "localhost";
        static int port = 1972;

        // Connection objects
        BufferClient C;
        Header hdr;

        // Event counter for num events in buffer so far
        int nEvents;

        // Num samples in buffer so far
        public int nSamples;

        // Constructor
        public BufferComm() {

            // Create communication obj and init the data 
            C = new BufferClient();
            nEvents = 0;
            nSamples = 0;
        }

        // Connect to the buffer
        public void Connect() {

            C.connect(hostname, port);
            C.syncClocks();
        }

        // Return a float matrix array of the latest data in the FieldTrip buffer
        public float[,] GetData() {

            if (!C.isConnected()) return null;

            // Poll for the new data
            SamplesEventsCount sampevents = C.poll();

            // Remember the Num samples in buffer so far
            if (nSamples == 0) nSamples = sampevents.nSamples;
            if (sampevents.nSamples == nSamples) { return null; }
            if (sampevents.nSamples < nSamples) {
                if (C.isConnected()) C.syncClocks(); // re-sync the write client
                nSamples = sampevents.nSamples -1;
                return null;
            }

            // Get just the newest data
            float[,] data = C.getFloatData(nSamples, sampevents.nSamples - 1);

            // Update the Num samples in buffer so far
            nSamples = sampevents.nSamples - 1;

            return data;
        }

        // Get the values of the specified event type
        public double GetEvent(string commandType) {

            if (!C.isConnected()) return 0;

            // Poll for the new events
            SamplesEventsCount sampevents = C.poll();

            // Remember the num events in buffer so far
            if (nEvents == 0) nEvents = sampevents.nEvents-2;
            if (sampevents.nEvents - 1 == nEvents) { return -1; }
            if (sampevents.nEvents < nEvents) {
                if (C.isConnected()) C.syncClocks(); // re-sync the write client
                nEvents = sampevents.nEvents;
                return -1;
            }

            // Get just the newest events
            BufferEvent[] events = C.getEvents(nEvents, sampevents.nEvents - 1);

            // Update the Num events in buffer so far
            nEvents = sampevents.nEvents - 1;

            // Parse the event array and find the specified commandType event type
            // Return the value link to that event
            foreach (BufferEvent evt in events) {

                // check if the type is one we care about
                //ATTENTION: for buffer events use toString() lowercase NOT ToString()
                if (evt.getType().toString().Equals(commandType)) { // check if this event type matches

                    //Convert.ToSingle(evt.getValue().array);
                    //return Convert.ToSingle(evt.getValue().array);
                    return double.Parse(evt.getValue().toString());
                    //if (evt.getValue().toString().Equals(valueType)) { // check if the event value matches
                    //    processEvent(evt);
                    //}
                }
            }

            return -1;
        }

        public float[] GetEventArray(string commandType) {

            if (!C.isConnected()) return null;

            // Poll for the new events
            SamplesEventsCount sampevents = C.poll();

            // Remember the num events in buffer so far
            if (nEvents == 0) nEvents = sampevents.nEvents - 2;
            if (sampevents.nEvents - 1 == nEvents) { return null; }
            if (sampevents.nEvents < nEvents) {
                if (C.isConnected()) C.syncClocks(); // re-sync the write client
                nEvents = sampevents.nEvents;
                return null;
            }

            // Get just the newest events
            BufferEvent[] events = C.getEvents(nEvents, sampevents.nEvents - 1);

            // Update the Num events in buffer so far
            nEvents = sampevents.nEvents - 1;

            // Parse the event array and find the specified commandType event type
            // Return the array of values link to that event
            foreach (BufferEvent evt in events) {

                // check if the type is one we care about
                //ATTENTION: for buffer events use toString() lowercase NOT ToString()
                if (evt.getType().toString().Equals(commandType)) { // check if this event type matches

                    //Convert.ToSingle(evt.getValue().array);
                    //return Convert.ToSingle(evt.getValue().array);
                    //return double.Parse(evt.getValue().toString());
                    return (float[])evt.getValue().array;
                    //if (evt.getValue().toString().Equals(valueType)) { // check if the event value matches
                    //    processEvent(evt);
                    //}
                }
            }

            return null;
        }

        // Send the event to the FieldTrip buffer for int value
        public void SendEvent(string type, int value) {

            C.poll();
            BufferEvent E = new BufferEvent(type, value, -1);
            C.putEvent(E);
        }

        // Send the event to the FieldTrip buffer for string value
        public void SendEvent(string type, string value) {

            C.poll();
            BufferEvent E = new BufferEvent(type, value, -1);
            C.putEvent(E);
        }

        // Disconnect from the buffer
        public void Disconnect() {

            C.disconnect();
        }
    }
}
