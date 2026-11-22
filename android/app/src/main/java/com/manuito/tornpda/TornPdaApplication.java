package com.manuito.tornpda;

import android.app.Application;

public class TornPdaApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        HcppLaunchPolicy.installLoader(this);
    }
}
