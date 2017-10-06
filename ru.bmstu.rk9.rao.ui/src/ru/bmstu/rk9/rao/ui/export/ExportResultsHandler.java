package ru.bmstu.rk9.rao.ui.export;

import java.io.PrintWriter;
import java.util.List;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;

import ru.bmstu.rk9.rao.lib.result.AbstractResult;
import ru.bmstu.rk9.rao.lib.simulator.CurrentSimulator;

public class ExportResultsHandler extends AbstractHandler {

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		if (!ready())
			return null;

		exportResults();

		try {
			ResourcesPlugin.getWorkspace().getRoot().refreshLocal(IResource.DEPTH_INFINITE, null);
		} catch (CoreException e) {
		}

		return null;
	}

	public final static void exportResults() {
		if (!ready())
			return;

		List<AbstractResult<?>> results = CurrentSimulator.getResults();

		PrintWriter writer = RaoExportPrintWriter.initializeWriter(".res");
		if (writer == null)
			return;

		for (AbstractResult<?> result : results) {
			writer.println(result.getData().toString());
		}
		writer.close();
	}

	private final static boolean ready() {
		return CurrentSimulator.isInitialized() && !CurrentSimulator.getDatabase().getAllEntries().isEmpty();
	}
}
