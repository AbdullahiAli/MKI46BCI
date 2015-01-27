package com.dcc.fieldtripthreads.base;

public abstract class FieldtripThread {

	public abstract Argument[] getArguments();

	public abstract String getName();

	public abstract void mainloop();

	public abstract boolean validateArguments(Argument[] arguments);

}
