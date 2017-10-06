package ru.bmstu.rk9.rao.ui.export;

import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;

import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.IPath;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.ui.PlatformUI;

import ru.bmstu.rk9.rao.lib.modeldata.ModelStructureConstants;
import ru.bmstu.rk9.rao.lib.simulator.CurrentSimulator;

//TODO export to location chosen by user

public class RaoExportPrintWriter {
	final static PrintWriter initializeWriter(String suffix) {

		final IPath workspacePath = ResourcesPlugin.getWorkspace().getRoot().getLocation();
		final String projectName = CurrentSimulator.getStaticModelData().getModelStructure()
				.getString(ModelStructureConstants.NAME);
		IPath filePath = workspacePath.append(projectName).append(projectName + suffix);

		PrintWriter writer = null;
		try {
			writer = new PrintWriter(filePath.toString(), "UTF-8");
		} catch (FileNotFoundException | UnsupportedEncodingException e) {
			e.printStackTrace();
			MessageDialog.openError(PlatformUI.getWorkbench().getActiveWorkbenchWindow().getShell(), "Error",
					"Failed to initialize trace writer");
			return null;
		}

		return writer;
	}
}
