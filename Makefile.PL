use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'Spreadsheet::Write',
    'VERSION_FROM'  => 'lib/Spreadsheet/Write.pm',
    'PREREQ_PM'     => {
        'Spreadsheet::WriteExcel'   => '2.15',
        'Text::CSV'                 => '0.01',
    },
);
