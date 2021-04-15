import React from 'react';
import { UIManager, findNodeHandle } from 'react-native';


export default function RealTimeEnhancer(Chart) {
    return class RealTimeExtended extends Chart {
        appendN(data) {
            UIManager.dispatchViewManagerCommand(
                findNodeHandle(this.getNativeComponentRef()),
                UIManager.getViewManagerConfig(this.getNativeComponentName()).Commands.appendN,
                [data]
            );
        }

        updateFirstN(data) {
            UIManager.dispatchViewManagerCommand(
                findNodeHandle(this.getNativeComponentRef()),
                UIManager.getViewManagerConfig(this.getNativeComponentName()).Commands.updateFirstN,
                [data]
            );
        }
    }
}